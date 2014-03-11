require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/object/blank.rb'

class GenericHost
  def initialize(host_url)
    @host_url = host_url
  end

  def image_url
    puts "Parse images from #{URI.parse(@host_url).host}"

    #begin
      browser = Mechanize.new.get(@host_url)
      #page_images = browser.images_with(:src => /picture/, :mime_type => /jpg|jpeg|png/).reject {|s| %w(logo register banner).any? { |w| s.url.to_s.include?(w)}}

      #if page_images.blank?
        page_images = browser.images.select {|i| (i.url.to_s.downcase =~ /jpg|jpeg|png/).present? }
        page_images.reject! {|s| %w(rating layout).any? {|t| s.text.downcase.include?(t)} }
        page_images.reject! {|s| %w(logo counter register banner imgbox.png thumbnail adhance offline medal top bottom male female promotext close btn home).any? { |w| s.url.to_s.include?(w)}}
      #end
      puts "No images found at : #{@host_url}" if page_images.blank?

      page_images.first.url.to_s rescue nil

    # rescue StandardError => e
    #   puts "error = #{e.to_s} at page #{post_page.uri.to_s}"
    #   Rails.logger.error e.to_s
    #   page_images = []
    # ensure
    #   page_images.first
    # end
  end
end