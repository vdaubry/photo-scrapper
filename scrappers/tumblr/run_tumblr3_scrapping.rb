#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr3_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr3"]["url"]
tumblr3 = Tumblr3Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr3)
scrapper.start
