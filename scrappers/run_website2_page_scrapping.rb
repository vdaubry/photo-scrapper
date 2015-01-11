#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/website2_page_scrapper'

specific_model = ARGV[0]
puts "specific_model = #{specific_model}"
exit unless specific_model != nil

# a mareger avec website2scrapping (pas besoin de 2 script, faire un if sur ARGV[1])

url = YAML.load_file('private-conf/websites.yml')["website2"]["url"]
website2 = Website2PageScrapper.new(url, specific_model)
scrapper = WebsiteScrapper.new(website2)
scrapper.start
