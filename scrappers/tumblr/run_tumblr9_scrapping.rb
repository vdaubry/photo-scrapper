#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr9_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr9"]["url"]
tumblr9 = Tumblr9Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr9)
scrapper.start
