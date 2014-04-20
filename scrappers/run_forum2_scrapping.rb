#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/forum2_scrapper'

url = YAML.load_file('private-conf/forums.yml')["forum2"]["url"]
forum2 = Forum2Scrapper.new(url)
scrapper = WebsiteScrapper.new(forum2)
scrapper.start
