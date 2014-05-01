#!/usr/bin/ruby
require_relative '../scrapper_conf'
ScrapperConf.load

require_relative '../../websites/website_scrapper'
require_relative '../../websites/tumblr/tumblr7_scrapper'

url = YAML.load_file('private-conf/tumblr.yml')["tumblr7"]["url"]
tumblr7 = Tumblr7Scrapper.new(url)
scrapper = WebsiteScrapper.new(tumblr7)
scrapper.start
