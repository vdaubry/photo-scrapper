require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/array/access.rb'
require 'active_support/time'
require_relative '../models/website'
require_relative '../models/image'
require_relative '../models/post'
require_relative 'navigation'
require_relative 'download'


class Scrapper
  include Navigation
  include Download
  extend Forwardable
  def_delegators :@website, :url, :id

  attr_accessor :website, :current_page, :current_post_name, :post_id

  def initialize(url)
    websites = Website.find_by(url)
    if websites.nil?
      raise "Website search failed"
    else 
      @website = websites.first
    end
  end

  def authorize
  end
end