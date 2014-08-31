#!/usr/bin/ruby

require_relative 'scrapper_conf'
require_relative 'scrapper_factory'
ScrapperConf.load

path = File.expand_path('../websites', File.dirname(__FILE__))
Dir[path+"/**/*.rb"].each {|file| require file}

puts "Start polling messages from website queue"
Facades::SQS.new(ENV["WEBSITE_QUEUE_NAME"]).poll do |msg|
  puts "Found website to scrap : #{msg}"
  json_msg = JSON.parse(msg)
  key = json_msg["website_key"].tap {|k| puts "Found key : #{k}"}
  scrapper = ScrapperFactory.new(key).scrapper
  WebsiteScrapper.new(scrapper).start
end