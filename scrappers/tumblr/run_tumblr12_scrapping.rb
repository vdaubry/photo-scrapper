#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr12_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr12"]["url"]
tumblr12 = Tumblr12Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr12)
scrapper.start
