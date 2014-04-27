#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/tumblr2_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr2"]["url"]
tumblr2 = Tumblr2Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr2)
scrapper.start
