#!/usr/bin/ruby
require_relative 'scrapper_conf'
ScrapperConf.load

require_relative '../websites/website_scrapper'
require_relative '../websites/forum5_scrapper'

url = YAML.load_file('config/forums.yml')["forum5"]["url"]
forum5 = Forum5Scrapper.new(url)
scrapper = WebsiteScrapper.new(forum5)
scrapper.start
