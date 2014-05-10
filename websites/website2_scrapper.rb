require_relative 'scrapper'

class Website2Scrapper < Scrapper
  attr_accessor :has_next_page, :model_id, :specific_model

  def do_scrap
    if @specific_model
      base_url = YAML.load_file('private-conf/websites.yml')["website2"]["base_url"]
      scrap_specific_page("#{base_url}/#{@specific_model}", @specific_model)
    else
      excluded_urls = YAML.load_file('private-conf/websites.yml')["website2"]["excluded_urls"]
      scrap_allowed_links(excluded_urls, scrapping_date)
    end
    
  end

  def allowed_links(excluded_urls)
    @current_page.links.map {|link| link if link.text.present? && !excluded_urls.any? {|s| link.href.include?(s)} && link.href.size>1}.compact
  end

  def images_links(page)
    doc = page.parser
    doc.xpath("//div[@class='pic ']//a")
  end

  def next_page_button(page)
    doc = page.parser
    doc.xpath("//button[@onclick]").select {|node| node.text.match('Load.*more').present?}.first
  end

  def model_id(page)
    page.link_with(:text => "Upload Here").href.split('/').last
  end

  def lastpid(page)
    doc = page.parser
    doc.xpath("//div[@class='pic ']//a").last.attributes["id"].value.split('link')[1]
  end

  def find_latest_pic_date(page)
    #check current page date 
    doc = page.parser
    pid = doc.css("div.pic").first.children[1].text.split("id. ").last
    post_url = YAML.load_file('private-conf/websites.yml')["website2"]["post_url"]
    browser = Mechanize.new
    response_doc = browser.post(post_url, {"req" => "pexpand", "pid" => pid}).parser
    response_doc.xpath("//body").children[0].text.split("added on: ").last
  end

  def scrap_allowed_links(excluded_urls, previous_scrapping_date)
    allowed_links(excluded_urls).each do |link|
      post_name = link.text
      post = Post.create(id, post_name)
      return if post.banished

      @post_id = post.id
      
      pp "Scrap : #{post.name} since #{previous_scrapping_date}"
      page = link.click

      button = next_page_button(page)
      @has_next_page = button.present?
      @model_id = model_id(page)
      scrap_page(page, previous_scrapping_date)
    end
  end

  def scrap_specific_page(page_name, post_name)
    page = Mechanize.new.get(page_name)
    post = Post.create(id, post_name)
    @post_id = post.id

    button = next_page_button(page)
    @has_next_page = button.present?
    @model_id = model_id(page)
    scrap_page(page, 10.year.ago)
  end

  def scrap_page(page, previous_scrapping_date)
    added_on = find_latest_pic_date(page)
    puts "latest pic is #{added_on}"

    if Date.parse(added_on) >= previous_scrapping_date
      img_links = images_links(page)
      puts "Found #{img_links.count} images"

      img_links.each do |img_link|
        url = img_link["href"]
        download_image(url)
      end

      go_to_next_page(page, previous_scrapping_date)
    else
      puts "No new images since #{previous_scrapping_date}"
    end
  end

  def go_to_next_page(page, previous_scrapping_date)
    #next page
    if @has_next_page
      puts "Loading next page"
      lastpid = lastpid(page)
      post_url = YAML.load_file('private-conf/websites.yml')["website2"]["post_url"]
      page = Mechanize.new.post(post_url, {"req" => "morepics", "cid" => @model_id, "lastpid" => lastpid})

      remaining_images = page.content.split("|")[1]
      @has_next_page = remaining_images.to_i>0

      scrap_page(page, previous_scrapping_date)
    end
  end
end