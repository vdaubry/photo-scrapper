require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr6Scrapper < Scrapper
  include TumblrHelper

  def single_photo_links
    doc = @current_page.parser
    doc.xpath('//div[@class="bg rounded"]').map { |div| div[:style].scan(/http.*(?=')/).first}
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr5"]["post_name"]
  end
  
  def is_current_page_last_page
    @current_page.parser.xpath('//div[contains(@class, "post")]').blank?
  end
end