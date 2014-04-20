#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/website1_scrapper'

url = YAML.load_file('private-conf/websites.yml')["website1"]["url"]
website1 = Website1Scrapper.new(url)
scrapper = WebsiteScrapper.new(website1)
scrapper.start
