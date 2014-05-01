require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr4Scrapper < Scrapper
  include TumblrHelper

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr4"]["post_name"]
  end
end