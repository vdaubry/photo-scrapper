require 'rubygems'
require 'bundler/setup'
require 'httparty'
require_relative '../config/application'
require_relative 'api_helper'

class Post
  include HTTParty
  extend ApiHelper

  def self.create(website_id, name)
    set_base_uri
    retry_call do
      resp = post("/websites/#{website_id}/posts.json", :body => {:post => {:name => name}})
      Post.new(resp["post"])
    end
  end

  def self.destroy(website_id, id)
    set_base_uri
    retry_call do
      delete("/websites/#{website_id}/posts/#{id}.json")
    end
  end

  def self.find_by(website_id, page_url)
    set_base_uri
    retry_call do
      resp = get("/websites/#{website_id}/posts/search.json", :query => {:post => {:page_url => page_url}})
      posts = resp["posts"]
      posts.map {|post| Post.new(post)}
    end
  end

  def self.update(website_id, id, page_url)
    set_base_uri
    retry_call do
      resp = put("/websites/#{website_id}/posts/#{id}.json", :body => {:post => {:page_url => page_url}})
      Post.new(resp["post"])
    end
  end

  def initialize(json)
    @json = json
  end

  def name
    @json["name"]
  end

  def id
    @json["id"]
  end 
end
