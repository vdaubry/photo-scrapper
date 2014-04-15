#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/website2_scrapper'

specific_model = ARGV[0]
puts "specific_model = #{specific_model}"
exit unless specific_model != nil

url = YAML.load_file('config/websites.yml')["website2"]["url"]
website2 = Website2Scrapper.new(url)
website2.specific_model = ARGV[0]
scrapper = WebsiteScrapper.new(website2)
scrapper.start
