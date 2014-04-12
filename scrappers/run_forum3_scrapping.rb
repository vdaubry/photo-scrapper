#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/forum3_scrapper'

url = YAML.load_file('config/forums.yml')["forum3"]["url"]
forum3 = Forum3Scrapper.new(url)
scrapper = WebsiteScrapper.new(forum3)
scrapper.start
