require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr12Scrapper < Scrapper
  include TumblrHelper
  
  def direct_images_urls
    doc = @current_page.parser
    doc.xpath('//div[@class="attachment"]/a/img').map {|img| img.attr('data-highres')}
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr12"]["post_name"]
  end
  
  def is_current_page_last_page
    @current_page.parser.xpath('//div[@id="posts-container"]//div').blank?
  end
end