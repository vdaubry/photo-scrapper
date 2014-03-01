require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative '../config/application'

class WebsiteApi
  include HTTParty
  base_uri PHOTO_DOWNLOADER_URL

  def search(url)
    resp = self.class.get("/websites/search.json", :query => {:url => url})
    Website.new(resp)
  end
end


class Website
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def last_scrapping_date
    date_str = json["website"]["last_scrapping_date"]
    Date.parse(date_str)
  end
end