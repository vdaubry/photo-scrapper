require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/array/access.rb'

class Website1

  attr_reader :url
  attr_accessor :current_page
  attr_accessor :current_post

  def initialize(url)
    @url = url
  end

  def home_page
    @current_page = Mechanize.new.get(url)
  end

  def previous_month
    previous_month = website.last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (website.last_scrapping_date - 1.month).beginning_of_month
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

  def scrap_category(category, previous_month)
    @current_post = "#{category}_#{previous_month.strftime("%Y_%B")}"

    pp "Scrap category : #{category} - #{previous_month.strftime("%Y/%B")}"
    page = @current_page.link_with(:text => category).click
    page = page.link_with(:text => previous_month.strftime("%Y")).click
    page = page.link_with(:text => previous_month.strftime("%B")).click

    #post = scrapping.posts.find_or_create_by(:name => "#{category}_#{previous_month.strftime("%Y_%B")}")
    #post.update_attributes(:website => website, :status => Post::TO_SORT_STATUS)

    link_reg_exp = YAML.load_file('config/websites.yml')["website1"]["link_reg_exp"]
    links = page.links_with(:href => %r{#{link_reg_exp}})#[0..1]
    pp "Found #{links.count} links" 
    links.each do |link|
      download_image(link)
    end

    #post.destroy if post.images.count==0
  end

  def download_image(link)
    pp "download"
    # page = link.click
    # page_image = page.image_with(:src => %r{/norm/})
    # if page_image
    #   url = page_image.url.to_s

    #   image = Image.where(:source_url => url).first
    #   if image.nil?
    #     image = Image.new.build_info(url, website, post)
    #     pp "Save #{image.key}"
    #     image.download
    #     sleep(1)
    #   end
    # end
  end

end