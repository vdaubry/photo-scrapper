#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require_relative 'config/application'
require_relative 'models/website_api'
require_relative 'websites/website1'

Dotenv.load

url = YAML.load_file('config/websites.yml')["website1"]["url"]
website = Website1.new(url)

start_time = DateTime.now
current_month = website.next_month

pp "Start scrapping #{url} for month : #{current_month}"

website.home_page

pp "Sign in user : #{user}"
user = YAML.load_file('config/websites.yml')["website1"]["username"]
password = YAML.load_file('config/websites.yml')["website1"]["password"]
top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
website.sign_in(user, password)

top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
top_page = website.top_page(top_link)

images_saved = 0
(1..12).each do |category_number|
  category_name = YAML.load_file('config/websites.yml')["website1"]["category#{category_number}"]
  category_page = website.category(category_name, current_month)
  website.scrap_category(category_page, current_month)
  #images_saved+=post.where(:name => "#{category_name}_#{previous_month.strftime("%Y_%B")}").images.count
end