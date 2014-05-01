#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr4_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr4"]["url"]
tumblr4 = Tumblr4Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr4)
scrapper.start
