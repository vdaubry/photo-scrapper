#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr10_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr10"]["url"]
tumblr10 = Tumblr10Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr10)
scrapper.start
