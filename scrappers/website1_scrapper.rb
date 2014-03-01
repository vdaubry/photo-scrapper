#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
require 'config/application'
require 'models/website_api'

pp "Start scrapping #{website.url} for month : #{previous_month}"

url = YAML.load_file('config/websites.yml')["website1"]["url"]
website = website1.new(url)

start_time = DateTime.now
previous_month = website.previous_month.strftime("%Y/%B")

pp "Sign in user : #{user}"
user = YAML.load_file('config/websites.yml')["website1"]["username"]
password = YAML.load_file('config/websites.yml')["website1"]["password"]
top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
website.sign_in(user, password, top_link)

images_saved = 0
(1..12).each do |category_number|
  category_name = YAML.load_file('config/websites.yml')["website1"]["category#{category_number}"]
  website.scrap_category(top_page, category_name, previous_month, website, scrapping) 
  images_saved+=post.where(:name => "#{category_name}_#{previous_month.strftime("%Y_%B")}").images.count
end