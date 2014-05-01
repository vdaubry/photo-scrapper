#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr8_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr8"]["url"]
tumblr8 = Tumblr8Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr8)
scrapper.start
