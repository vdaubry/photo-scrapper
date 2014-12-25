require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative 'api_helper'
require_relative '../config/application'

class Website
  include HTTParty
  extend ApiHelper

  def self.find_by(url)
    set_base_uri
    retry_call do
      resp = get("/websites/search.json", :query => {:url => url})

      if resp.code != 200
        puts "API Failed with response : #{resp}"
        return
      end

      websites = resp["websites"]
      websites.map {|json| Website.new(json)}
    end
  end

  def initialize(json)
    @json = json
  end

  def url
    @json["url"]
  end

  def id
    @json["id"]
  end
end
