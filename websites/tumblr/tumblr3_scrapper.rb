require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr3Scrapper < Scrapper
  include TumblrHelper

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr3"]["post_name"]
  end
end