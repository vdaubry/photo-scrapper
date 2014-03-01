#!/usr/bin/ruby

url = YAML.load_file('config/websites.yml')["website1"]["url"]

website = Website.new(url)