#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/website3_scrapper'

url = YAML.load_file('private-conf/websites.yml')["website3"]["url"]
website3 = Website3Scrapper.new(url)
scrapper = WebsiteScrapper.new(website3)
scrapper.start
