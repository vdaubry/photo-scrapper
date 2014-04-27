#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/tumblr/tumblr1_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["url"]
tumblr1 = Tumblr1Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr1)
scrapper.start
