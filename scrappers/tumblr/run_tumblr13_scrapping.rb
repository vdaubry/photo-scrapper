#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr13_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr13"]["url"]
tumblr13 = Tumblr13Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr13)
scrapper.start
