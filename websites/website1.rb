require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/array/access.rb'
require 'active_support/time'
require_relative '../models/website_api'
require_relative '../models/image_api'
require_relative '../models/post_api'

class Website1

  attr_accessor :website
  attr_accessor :current_page
  attr_accessor :current_post
  attr_accessor :post_images_count

  def initialize(url)
    @website = WebsiteApi.new.search(url).first
  end

  def home_page
    @current_page = Mechanize.new.get(@website.url)
  end

  def previous_month
    previous_month = @website.last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (@website.last_scrapping_date - 1.month).beginning_of_month
  end

  def sign_in(user, password)
    sign_in_page = @current_page.links.find { |l| l.text == 'Log-in' }.click
    @current_page = sign_in_page.form_with(:name => nil) do |form|
      form.fields.second.value = user
      form.fields.third.value = password
    end.submit
  end

  def top_page(top_link)
    @current_page = @current_page.link_with(:text => top_link).click
  end

  def category(category_name, previous_month)
    pp "Go to category : #{category_name} - #{previous_month.strftime("%Y/%B")}"
    @current_post = "#{category_name}_#{previous_month.strftime("%Y_%B")}"

    page = @current_page.link_with(:text => category_name).click
    page = page.link_with(:text => previous_month.strftime("%Y")).click
    page.link_with(:text => previous_month.strftime("%B")).click
  end

  def scrap_category(category_page)
    puts "@website.id = #{@website.id}"
    puts "previous_month = #{previous_month.strftime("%Y_%B")}"

    post = PostApi.new.create(@website.id, "#{@current_post}_#{previous_month.strftime("%Y_%B")}")
    @post_images_count = 0
    
    link_reg_exp = YAML.load_file('config/websites.yml')["website1"]["link_reg_exp"]
    links = category_page.links_with(:href => %r{#{link_reg_exp}})#[0..1]
    pp "Found #{links.count} links" 
    links.each do |link|
      parse_image(link)
    end

    PostApi.new.destroy(@website.id, post.id) if @post_images_count==0
  end

  def parse_image(link)
    page = link.click
    page_image = page.image_with(:src => %r{/norm/})

    if page_image
      image_url = page_image.url.to_s

      image = ImageApi.new.search(@url, image_url).first
      if image.nil?
        download_image(image_url)
      end
    end
  end

  def download_image(url)
    # image = Image.new.build_info(url, website, post)
    # pp "Save #{image.key}"
    # image.download
    # sleep(1)
  end

end