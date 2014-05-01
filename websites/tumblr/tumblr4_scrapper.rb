require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr4Scrapper < Scrapper
  include TumblrHelper

  def direct_images_urls
    doc = @current_page.parser
    doc.xpath('//div[@class="media"]//img[not(parent::a)]').map {|img| img[:src]}
  end

  def single_photo_links
    doc = @current_page.parser

    direct_images = direct_images_urls
    links_to_image = []
    doc.xpath('//div[@class="media"]//a').each do |link|
      if link[:href] .include?(url)
        links_to_image << link[:href] 
      else
        direct_images << link.xpath('//img').first[:src]
      end
    end
    links_to_image = links_to_image.map {|link| image_at_link(link)}

    links_to_image+direct_images
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr4"]["post_name"]
  end
end