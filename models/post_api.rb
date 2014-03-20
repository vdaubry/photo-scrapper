require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative '../config/application'
require_relative 'api_helper'

class PostApi
  include HTTParty
  include ApiHelper
  
  def initialize
    self.class.base_uri ENV['PHOTO_DOWNLOADER_URL']
  end

  def create(website_id, name)
    retry_call do
      resp = self.class.post("/websites/#{website_id}/posts.json", :body => {:post => {:name => name}})
      Post.new(resp["post"])
    end
  end

  def destroy(website_id, id)
    retry_call do
      self.class.delete("/websites/#{website_id}/posts/#{id}.json")
    end
  end

  def search(website_id, page_url)
    retry_call do
      resp = self.class.get("/websites/#{website_id}/posts/search.json", :query => {:post => {:page_url => page_url}})
      posts = resp["posts"]
      posts.map {|post| Post.new(post)}
    end
  end

  def update(website_id, id, page_url)
    retry_call do
      resp = self.class.put("/websites/#{website_id}/posts/#{id}.json", :body => {:post => {:page_url => page_url}})
      Post.new(resp["post"])
    end
  end
end


class Post
  attr_accessor :json

  def initialize(json)
    @json = json
  end

  def name
    json["name"]
  end

  def id
    json["id"]
  end  
end