require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr5Scrapper < Scrapper
  include TumblrHelper

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr5"]["post_name"]
  end
  
  def is_current_page_last_page
    @current_page.parser.xpath('//section[@id="posts"]//article').blank?
  end
end