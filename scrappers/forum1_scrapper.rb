#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative '../config/application'
require_relative '../models/website_api'
require_relative '../models/scrapping_api'
require_relative '../websites/forum1'

Dotenv.load(
  File.expand_path("../../.#{APP_ENV}.env", __FILE__),
  File.expand_path("../../.env",  __FILE__))

url = YAML.load_file('config/forums.yml')["forum1"]["url"]
website = Forum1.new(url)

start_time = DateTime.now
last_scrapping_date = website.last_scrapping_date

scrapping = ScrappingApi.new.create(website.website.id, start_time)

website.home_page

user = YAML.load_file('config/forums.yml')["forum1"]["username"]
password = YAML.load_file('config/forums.yml')["forum1"]["password"]
pp "Sign in user : #{user}"
website.sign_in(user, password)

pp "Start scrapping #{url} new images since : #{last_scrapping_date}"

(1..2).each do |category_number|
  category_name = YAML.load_file('config/forums.yml')["forum1"]["category#{category_number}"]
  website.scrap_posts_from_category(category_name, last_scrapping_date)
end

ScrappingApi.new.update(website.website.id, scrapping.id, {:success => true, :duration => DateTime.now-start_time})