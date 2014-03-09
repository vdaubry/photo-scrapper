#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative '../config/application'
require_relative '../websites/website2'

Dotenv.load

url = YAML.load_file('config/websites.yml')["website2"]["url"]
website = Website2.new(url)

start_time = DateTime.now
last_scrapping_date = website.last_scrapping_date

pp "Start scrapping #{url} for new images since : #{last_scrapping_date}"

website.home_page

excluded_urls = YAML.load_file('config/websites.yml')["website2"]["excluded_urls"]
website.scrap_allowed_links(excluded_urls, last_scrapping_date)