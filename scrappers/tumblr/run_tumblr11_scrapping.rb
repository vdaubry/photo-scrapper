#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr11_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr11"]["url"]
tumblr11 = Tumblr11Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr11)
scrapper.start
