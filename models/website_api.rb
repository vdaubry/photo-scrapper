require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative 'api_helper'
require_relative '../config/application'

class WebsiteApi
  include HTTParty
  include ApiHelper

  def initialize
    self.class.base_uri ENV['PHOTO_DOWNLOADER_URL']
  end

  def search(url)
    retry_call do
      resp = self.class.get("/websites/search.json", :query => {:url => url})

      if resp.code != 200
        puts "API Failed with response : #{resp}"
        return
      end

      websites = resp["websites"]
      websites.map {|website| Website.new(website)}
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
    Date.parse(date_str) unless date_str.nil?
  end

  def url
    json["url"]
  end

  def id
    json["id"]
  end
end