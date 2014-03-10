#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative '../config/application'
require_relative '../models/website_api'
require_relative '../websites/forum1'

Dotenv.load

url = YAML.load_file('config/forums.yml')["forum1"]["url"]
website = Forum1.new(url)

start_time = DateTime.now
last_scrapping_date = website.last_scrapping_date

website.home_page

pp "Sign in user : #{user}"
user = YAML.load_file('config/forums.yml')["forum1"]["username"]
password = YAML.load_file('config/forums.yml')["forum1"]["password"]
website.sign_in(user, password)

pp "Start scrapping #{url} new images since : #{last_scrapping_date}"

(1..2).each do |category_number|
  category_name = YAML.load_file('config/forums.yml')["forum1"]["category#{category_number}"]
  website.scrap_category(category_name, last_scrapping_date)
end