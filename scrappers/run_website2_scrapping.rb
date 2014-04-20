#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/website2_scrapper'

url = YAML.load_file('private-conf/websites.yml')["website2"]["url"]
website2 = Website2Scrapper.new(url)
scrapper = WebsiteScrapper.new(website2)
scrapper.start
