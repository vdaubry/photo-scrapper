require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/array/access.rb'
require 'active_support/time'
require_relative '../models/scrapper_bloom_filter.rb'
require_relative '../models/facades/s3.rb'
require_relative 'navigation'
require_relative 'download'

class Scrapper
  include Navigation
  include Download
  extend Forwardable
  
  attr_accessor :current_page
  
  def initialize(website_name, website_url, params=nil)
    @params = params
    @website = Website.new(website_name, website_url)
    filter_path = "tmp/#{website_name}.bloom.dump"
    Facades::S3.new.read("#{website_name}.bloom.dump", filter_path)
    @bloom_filter = ScrapperBloomFilter.new(filter_path)
  end
  
  def url
    @website.url
  end
  
  def save_filter
    @bloom_filter.save
  end

  def authorize
  end
  
  class Website
    attr_accessor :name, :url
    
    def initialize(name, url)
      @name = name
      @url = url
    end
  end
  
  class Post
    attr_accessor :name, :url, :website
    
    def initialize(name, url, website)
      @website = website
      @name = name
      @url = url
    end
    
    def to_s
      "#{@name} - #{url}"
    end
    
    def send_create_msg
      json = {:website_id => @website.url, :post_id => @url, :post_name => @name}.to_json
      Facades::SQS.new(ENV["POST_QUEUE_NAME"]).send(json) unless ENV['TEST']
    end
  end
end