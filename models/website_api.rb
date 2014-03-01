require 'rubygems'
require 'bundler/setup'
require 'httparty'

class WebsiteApi
  include HTTParty
  base_uri PHOTO_DOWNLOADER_URL

  def get
    resp = self.class.get("/websites/#{website}/posts/#{post}/images.json", :query => {:page => page, :status => status})
    Website.new(resp)
  end
end


class Website
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def last_scrapping_date
    json["last_scrapping_date"]
  end
end