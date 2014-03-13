require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/object/blank.rb'

class GenericHost
  def initialize(host_url)
    @host_url = host_url
  end

  def page_image
    puts "Parse images from #{URI.parse(@host_url).host}"
    page_images = []
    begin
      browser = Mechanize.new.get(@host_url)
      #page_images = browser.images_with(:src => /picture/, :mime_type => /jpg|jpeg|png/).reject {|s| %w(logo register banner).any? { |w| s.url.to_s.include?(w)}}

      #if page_images.blank?
        page_images = browser.images.select {|i| (i.url.to_s.downcase =~ /jpg|jpeg|png/).present? }
        page_images.reject! {|s| %w(rating layout).any? {|t| s.text.downcase.include?(t)} }
        page_images.reject! {|s| %w(logo counter register banner imgbox.png thumbnail adhance offline medal top bottom male female promotext close btn home).any? { |w| s.url.to_s.include?(w)}}
      #end
      puts "No images found at : #{@host_url}" if page_images.blank?
    rescue Mechanize::ResponseCodeError => e
      puts "error = #{e.to_s} at page #{@host_url}"
    ensure
      return page_images.first rescue nil
    end
  end

  def image_url
    return page_image.url.to_s rescue nil
  end
    
end