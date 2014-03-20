require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative 'api_helper'
require_relative '../config/application'

class ScrappingApi
  include HTTParty
  include ApiHelper
  
  def initialize
    self.class.base_uri ENV['PHOTO_DOWNLOADER_URL']
  end

  def create(website_id, date)
    retry_call do
      resp = self.class.post("/websites/#{website_id}/scrappings.json", :body => {:scrapping => {:date => date.to_s}})
      Scrapping.new(resp["scrapping"])
    end
  end

  def update(website_id, id, params)
    retry_call do
      resp = self.class.put("/websites/#{website_id}/scrappings/#{id}.json", :body => {:scrapping => params})
      Scrapping.new(resp["scrapping"])
    end
  end
end


class Scrapping
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def date
    json["date"]
  end

  def id
    json["id"]
  end  
end