require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr9Scrapper < Scrapper
  include TumblrHelper

  def single_photo_xpath
    '//div[@class="photo-wrap"]//a'
  end

  def photoset_links
    links = []
    @current_page.iframes.each do |iframe|
      photoset = iframe.click
      doc = photoset.parser
      links += doc.xpath('//div[@class="photo"]//img').map {|img| img[:src]}
    end
    links
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr9"]["post_name"]
  end
  
  def is_current_page_last_page
    @current_page.parser.xpath('//section[@id="posts"]//article').blank?
  end
end