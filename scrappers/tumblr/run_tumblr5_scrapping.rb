#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr5_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr5"]["url"]
tumblr5 = Tumblr5Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr5)
scrapper.start
