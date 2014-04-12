#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative '../config/application'
require_relative '../models/scrapping_api'
require_relative '../websites/website2'

Dotenv.load(
  File.expand_path("../../.#{APP_ENV}.env", __FILE__),
  File.expand_path("../../.env",  __FILE__))

url = YAML.load_file('config/websites.yml')["website2"]["url"]
website = Website2.new(url)

start_time = DateTime.now
scrapping = ScrappingApi.new.create(website.website.id, start_time)

page = ARGV[0]
base_url = YAML.load_file('config/websites.yml')["website2"]["base_url"]

website.scrap_specific_page("#{base_url}/#{page}", page)

ScrappingApi.new.update(website.website.id, scrapping.id, {:success => true, :duration => DateTime.now-start_time})