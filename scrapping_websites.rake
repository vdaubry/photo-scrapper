# encoding: utf-8

namespace :websites do

    desc "Scrap websites in websites.yml"
    task :reset  => :environment do
      Image.delete_all
      Scrapping.delete_all
      FileUtils.rm_rf image_path
      FileUtils.mkdir_p Image.thumbnail_path
      FileUtils.cp 'lib/calinours_mini.jpg', "#{Image.thumbnail_path}/calinours.jpg"
      FileUtils.cp 'lib/calinours.jpg', "#{image_path}/calinours.jpg"

      FileUtils.rm_rf('ressources')
      FileUtils.mkdir_p 'ressources/to_keep'
    end


#########################################################################################################
#
# Website1
#
#########################################################################################################


  desc "Scrap website1 in websites.yml"
  task :website1  => :environment do
  	require 'open-uri'
    require 'digest/md5'

  	url = YAML.load_file('config/websites.yml')["website1"]["url"]

    website = Website.where(:url => url).first

  	last_scrapping = Scrapping.where(:success => true, :website => website).asc(:date).limit(1).first
    previous_month = last_scrapping.nil? ? 1.month.ago.beginning_of_month : (last_scrapping.date - 1.month).beginning_of_month

  	scrapping = Scrapping.find_or_create_by(:date => previous_month, :website => website)
  	start_time = DateTime.now
	    
    user = YAML.load_file('config/websites.yml')["website1"]["username"]
    password = YAML.load_file('config/websites.yml')["website1"]["password"]
    top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]

    pp "Start scrapping #{url} for month : #{previous_month.strftime("%Y/%B")}"
    home_page = Mechanize.new.get(url)

    pp "Sign in user : #{user}"
    sign_in_page = home_page.links.find { |l| l.text == 'Log-in' }.click
    page = sign_in_page.form_with(:name => nil) do |form|
    	form.fields.second.value = user
    	form.fields.third.value = password
    end.submit
  	
  	top_page = page.link_with(:text => top_link).click

    images_saved = 0
  	(1..12).each do |category_number|
      category_name = YAML.load_file('config/websites.yml')["website1"]["category#{category_number}"]
  		scrap_category(top_page, category_name, previous_month, website, scrapping) 
      images_saved+=post.where(:name => "#{category_name}_#{previous_month.strftime("%Y_%B")}").images.count
  	end

  	scrapping.update_attributes(
  	  success: true,
  	  duration: DateTime.now-start_time,
  	  image_count: images_saved
  	)
  end

  def scrap_category(page, category, previous_month, website, scrapping)
  	pp "Scrap category : #{category} - #{previous_month.strftime("%Y/%B")}"
   	page = page.link_with(:text => category).click
   	page = page.link_with(:text => previous_month.strftime("%Y")).click
   	page = page.link_with(:text => previous_month.strftime("%B")).click

    post = scrapping.posts.find_or_create_by(:name => "#{category}_#{previous_month.strftime("%Y_%B")}")
    post.update_attributes(:website => website, :status => Post::TO_SORT_STATUS)

   	link_reg_exp = YAML.load_file('config/websites.yml')["website1"]["link_reg_exp"]
   	links = page.links_with(:href => %r{#{link_reg_exp}})#[0..1]
   	pp "Found #{links.count} links" 
   	links.each do |link|
   		page = link.click
   		page_image = page.image_with(:src => %r{/norm/})
      if page_image
        url = page_image.url.to_s

        image = Image.where(:source_url => url).first
        if image.nil?
          image = Image.new.build_info(url, website, post)
          pp "Save #{image.key}"
          image.download
          sleep(1)
        end
      end
   		
   	end

    post.destroy if post.images.count==0
  end


#########################################################################################################
#
# Website2
#
#########################################################################################################


  desc "Scrap website2 in websites.yml"
  task :website2  => :environment do
    require 'open-uri'
    require 'digest/md5'

    url = YAML.load_file('config/websites.yml')["website2"]["url"]
    website = Website.where(:url => url).first
    last_scrapping = Scrapping.where(:success => true, :website => website).asc(:date).limit(1).first
    previous_scrapping_date = last_scrapping.nil? ? 1.month.ago.beginning_of_month : last_scrapping.date

    new_scrapping = website.scrappings.create(:date => DateTime.now)
    start_time = DateTime.now

    pp "Start scrapping #{url} new images since : #{previous_scrapping_date}"
    home_page = Mechanize.new.get(url)
    excluded_urls = YAML.load_file('config/websites.yml')["website2"]["excluded_urls"]

    links = home_page.links.map {|link| link if link.text.present? && !excluded_urls.any? {|s| link.href.include?(s)} && link.href.size>1}.compact
    
    posts = []
    links.each do |link|
      post_name = link.text
      post = website.posts.find_or_create_by(:name => post_name)
      post.update_attributes(:scrapping => new_scrapping, :status => Post::TO_SORT_STATUS)
      posts << post
      scrap_page(link, post, website, previous_scrapping_date)
    end

    images_saved=posts.inject(0){|res, post| res + post.images.count}
    new_scrapping.update_attributes(
      success: true,
      duration: DateTime.now-start_time,
      image_count: images_saved
    )
  end


  desc "Scrap specific page of website2 in websites.yml"
  task :website2_page, [:id]  => :environment do |t, args|
    require 'open-uri'
    require 'digest/md5'

    url = YAML.load_file('config/websites.yml')["website2"]["url"]
    website = Website.where(:url => url).first

    new_scrapping = website.scrappings.create(:date => DateTime.now)
    start_time = DateTime.now

    base_url = YAML.load_file('config/websites.yml')["website2"]["base_url"]
    page_id = args.id
    page = Mechanize.new.get("#{base_url}/#{page_id}")
    pp "Start scrapping #{base_url}/#{page_id} all images"

    post_name = page_id.gsub('_', ' ')
    post = website.posts.find_or_create_by(:name => post_name)
    post.update_attributes(:scrapping => new_scrapping, :status => Post::TO_SORT_STATUS)

    scrap_current_page(page, 50.years.ago, website, post)

    post.destroy if post.images.count==0

    images_saved = post.images.count
    new_scrapping.update_attributes(
      success: true,
      duration: DateTime.now-start_time,
      image_count: images_saved
    )
  end


  def scrap_page(link, post, website, previous_scrapping_date)
    pp "Scrap : #{post.name} since #{previous_scrapping_date}"
    page = link.click
    scrap_current_page(page, previous_scrapping_date, website, post)
  end

  def scrap_current_page(page, previous_scrapping_date, website, post)
    #check current page date 
    doc = page.parser
    pid = doc.css("div.pic").first.children[1].text.split("id. ").last
    post_url = YAML.load_file('config/websites.yml')["website2"]["post_url"]
    browser = Mechanize.new
    response_doc = browser.post(post_url, {"req" => "pexpand", "pid" => pid}).parser
    added_on = response_doc.xpath("//body").children[0].text.split("added on: ").last

    puts "latest pic is #{added_on}"

    if Date.parse(added_on) > previous_scrapping_date
      img_links = page.links_with(:href=>/.jpg/)

      puts "Found #{img_links.count} images"

      img_links.each do |img_link|
        url = img_link.href

        image = Image.where(:source_url => url).first
        if image.nil?
          image = Image.new.build_info(url, website, post)
          pp "Save #{image.key}"
          image.download
          sleep(1)
        end
      end

      #next page
      cid = page.link_with(:text => "Upload Here").href.split('/').last
      button = doc.xpath("//button[@onclick]").select {|node| node.text == "Load 100 more"}.first
      if button
        puts "Loading next page"
        lastpid = button.attr("onclick").scan(/[0-9]/).join
        post_url = YAML.load_file('config/websites.yml')["website2"]["post_url"]
        page = browser.post(post_url, {"req" => "morepics", "cid" => cid, "lastpid" => lastpid})
        scrap_current_page(page, previous_scrapping_date, website, post)
      end
    end
  end
end
