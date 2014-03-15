#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative '../config/application'
require_relative '../websites/website2'
require_relative '../models/scrapping_api'

Dotenv.load(
  File.expand_path("../../.#{APP_ENV}.env", __FILE__),
  File.expand_path("../../.env",  __FILE__))

url = YAML.load_file('config/websites.yml')["website2"]["url"]
website = Website2.new(url)

start_time = DateTime.now
last_scrapping_date = website.last_scrapping_date

scrapping = ScrappingApi.new.create(website.website.id, start_time)

pp "Start scrapping #{url} for new images since : #{last_scrapping_date}"

website.home_page

excluded_urls = YAML.load_file('config/websites.yml')["website2"]["excluded_urls"]
website.scrap_allowed_links(excluded_urls, last_scrapping_date)

ScrappingApi.new.update(website.id, scrapping.id, {:success => true, :duration => DateTime.now-start_time})