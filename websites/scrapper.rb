require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/array/access.rb'
require 'active_support/time'
require_relative '../models/website'
require_relative '../models/image'
require_relative '../models/post'
require_relative '../models/image_downloader'

class Scrapper
  extend Forwardable
  def_delegators :@website, :url, :id, :scrapping_date

  attr_accessor :website, :current_page, :current_post_name, :post_images_count, :post_id

  def initialize(url)
    websites = Website.find_by(url)
    if websites.nil?
      raise "Website search failed"
    else 
      @website = websites.first
    end
  end

end