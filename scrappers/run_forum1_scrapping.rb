#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/forum1_scrapper'

url = YAML.load_file('private-conf/forums.yml')["forum1"]["url"]
forum1 = Forum1Scrapper.new(url)
scrapper = WebsiteScrapper.new(forum1)
scrapper.start
