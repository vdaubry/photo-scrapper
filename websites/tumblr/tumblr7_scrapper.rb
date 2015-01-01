require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr7Scrapper < Scrapper
  include TumblrHelper

  def direct_images_xpath
    '//div[@id="entry-deux"]//img[not(parent::a)]'
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr7"]["post_name"]
  end
  
  def is_current_page_last_page
    @current_page.parser.xpath('//div[@id="center"]//img').blank?
  end
end