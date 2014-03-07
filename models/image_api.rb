require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative '../config/application'

class ImageApi
  include HTTParty
  base_uri PHOTO_DOWNLOADER_URL

  def search(website_id, source_url)
    resp = self.class.get("/websites/#{website_id}/images/search.json", :query => {:source_url => source_url})
    images = resp["images"]
    images.map {|image| Image.new(image)}
  end

  def post(source_url, hosting_url, key, status, image_hash, width, height, file_size)
    resp = self.class.post("/websites/#{website_id}/images/search.json", :body => {:source_url => source_url})
  end
end


class Image
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def key
    json["key"]
  end

  def download
  end
end