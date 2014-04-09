require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative 'api_helper'
require_relative '../config/application'

class Scrapping
  include HTTParty
  extend ApiHelper

  def self.create(website_id, date)
    set_base_uri
    retry_call do
      resp = post("/websites/#{website_id}/scrappings.json", :body => {:scrapping => {:date => date.to_s}})
      Scrapping.new(resp["scrapping"])
    end
  end

  def self.update(website_id, id, params)
    set_base_uri
    retry_call do
      resp = put("/websites/#{website_id}/scrappings/#{id}.json", :body => {:scrapping => params})
      Scrapping.new(resp["scrapping"])
    end
  end

  def initialize(json)
    @json = json
  end

  def date
    @json["date"]
  end

  def id
    @json["id"]
  end
end
