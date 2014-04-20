#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/forum4_scrapper'

url = YAML.load_file('private-conf/forums.yml')["forum4"]["url"]
forum4 = Forum4Scrapper.new(url)
scrapper = WebsiteScrapper.new(forum4)
scrapper.start
