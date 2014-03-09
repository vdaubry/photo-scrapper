require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/array/access.rb'
require 'active_support/time'
require_relative '../models/website_api'
require_relative '../models/image_api'
require_relative '../models/post_api'
require_relative '../models/image_downloader'

class BaseWebsite
  attr_accessor :website, :current_page, :current_post_name, :post_images_count, :post_id

  def initialize(url)
    websites = WebsiteApi.new.search(url)
    if websites.nil?
      raise "Website search failed"
    else 
      @website = websites.first
    end
  end

end