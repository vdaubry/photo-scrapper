require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr10Scrapper < Scrapper
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
    YAML.load_file('private-conf/tumblr.yml')["tumblr10"]["post_name"]
  end
end