require_relative '../scrapper'
require_relative 'tumblr_helper'

class Tumblr13Scrapper < Scrapper
  include TumblrHelper
  
  def home_page
    agent = Mechanize.new
    agent.set_proxy("photo-visualizer.no-ip.org", 3128, "photo-visualizer", ENV['SQUID_PASSWORD']) unless ENV['TEST']
    @current_page = agent.get(url)
  end

  def post_name
    YAML.load_file('private-conf/tumblr.yml')["tumblr13"]["post_name"]
  end
end