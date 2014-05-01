#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr6_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr6"]["url"]
tumblr6 = Tumblr6Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr6)
scrapper.start
