require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr8Scrapper < Scrapper
  include TumblrHelper

  def single_photo_xpath
    '//div[@class="photo"]//a'
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr8"]["post_name"]
  end
end