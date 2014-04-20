require 'rubygems'
require 'bundler/setup'
require 'httparty'
require 'active_model'
require_relative '../config/application'
require_relative 'api_helper'

class Image
  include HTTParty
  extend ApiHelper

  def self.find_by(website_id, options={})
    set_base_uri
    retry_call do
      resp = get("/websites/#{website_id}/images/search.json", :body => options)

      if resp.code != 200
        puts "API Failed with response : #{resp.code} for search image with options : #{options}"
        return
      end
      images = resp["images"]
      images.map {|json| Image.new(json)}
    end
  end

  def self.create(website_id, post_id, source_url, hosting_url, key, status, image_hash, width, height, file_size)
    set_base_uri
    retry_call do
      resp = self.post("/websites/#{website_id}/posts/#{post_id}/images.json", :body => {:image => {:source_url => source_url, :hosting_url => hosting_url, :key => key, :status => status, :image_hash => image_hash, :width => width, :height => height, :file_size => file_size}})

      if resp.code == 422
        puts "API reject image with errors : #{resp["errors"]}"
        return
      elsif resp.code != 200
        puts "API image post failed with response : #{resp.code}"
        return
      end
      Image.new(resp["image"]) if resp["image"]
    end
  end

  def initialize(json)
    @json = json
  end

  def key
    @json["key"]
  end

  def hosting_url
    @json["hosting_url"]
  end
end