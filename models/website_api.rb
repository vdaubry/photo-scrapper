require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative '../config/application'

class WebsiteApi
  include HTTParty
  base_uri PHOTO_DOWNLOADER_URL

  def search(url)
    resp = self.class.get("/websites/search.json", :query => {:url => url})
    websites = resp["websites"]

    #If the api fails, it returns a string with stacktrace
    if websites!="websites"
      websites.map {|website| Website.new(website)}
    else
      puts "API Failed with response : #{resp}"
    end
  end
end


class Website
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def last_scrapping_date
    date_str = json["last_scrapping_date"]
    Date.parse(date_str)
  end

  def url
    json["url"]
  end

  def id
    json["id"]
  end
end