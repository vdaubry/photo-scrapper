require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr1Scrapper < Scrapper
  include TumblrHelper

  def single_photo_xpath
    '//div[@class="photo_holder"]//a'
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["post_name"]
  end
  
  def is_current_page_last_page
    @current_page.parser.xpath('//section[@id="posts"]//article').blank?
  end
end