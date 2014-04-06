#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative '../config/application'
require_relative '../models/scrapping_api'
require_relative '../websites/website1'

Dotenv.load(
  File.expand_path("../../.#{APP_ENV}.env", __FILE__),
  File.expand_path("../../.env",  __FILE__))

url = YAML.load_file('config/websites.yml')["website1"]["url"]
website = Website1.new(url)

start_time = DateTime.now
current_month = 1.month.ago.beginning_of_month#website.next_month

scrapping = ScrappingApi.new.create(website.website.id, current_month)

pp "Start scrapping #{url} for month : #{current_month}"

website.home_page

user = YAML.load_file('config/websites.yml')["website1"]["username"]
password = YAML.load_file('config/websites.yml')["website1"]["password"]
top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
pp "Sign in user : #{user}"
website.sign_in(user, password)

top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
top_page = website.top_page(top_link)

images_saved = 0
(1..12).each do |category_number|
  category_name = YAML.load_file('config/websites.yml')["website1"]["category#{category_number}"]
  category_page = website.category(category_name, current_month)
  website.scrap_category(category_page, current_month)
end

ScrappingApi.new.update(website.website.id, scrapping.id, {:success => true, :duration => DateTime.now-start_time})