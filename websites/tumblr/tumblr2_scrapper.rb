require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr2Scrapper < Scrapper
  include TumblrHelper

  def single_photo_xpath
    '//div[@class="photo-wrapper-inner"]//a'
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr2"]["post_name"]
  end

  def is_current_page_last_page
    @current_page.parser.xpath('//div[@class="post-wrapper clearfix"]').blank?
  end
end