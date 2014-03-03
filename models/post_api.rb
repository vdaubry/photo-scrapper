require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative '../config/application'

class PostApi
  include HTTParty
  base_uri PHOTO_DOWNLOADER_URL

  def create(website_id, name)
    resp = self.class.post("/websites/#{website_id}/posts.json", :body => {:post => {:name => name}})
    Post.new(resp)
  end
end


class Post
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def name
    json["post"]["name"]
  end
end