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

page = ARGV[0]
base_url = YAML.load_file('config/websites.yml')["website2"]["base_url"]

website.scrap_specific_page("#{base_url}/#{page}")