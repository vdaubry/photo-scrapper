require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'active_support/core_ext/object/blank.rb'

class GenericHost
  def initialize(host_url)
    @host_url = host_url
  end

  def all_images
    browser = Mechanize.new.get(@host_url)
    images = browser.images.select {|i| (i.url.to_s.downcase =~ /jpg|jpeg|png/).present? }
    images.reject! {|s| %w(rating layout).any? {|t| s.text.downcase.include?(t)} }
    images.reject! {|s| %w(logo counter register banner imgbox.png thumbnail thumb adhance stumbleupon delicious.png twitter.png myspace.png button_signin.jpg offline medal top bottom male female promotext close btn home 720p 1080p wmv).any? { |w| s.url.to_s.include?(w)}}
    images
  end

  def page_image
    puts "Parse images from #{URI.parse(@host_url).host}"
    page_images = []
    begin
      page_images = all_images

      puts "No images found at : #{@host_url}" if page_images.blank?
    rescue Mechanize::ResponseCodeError => e
      puts "error = #{e.to_s} at page #{@host_url}"
    rescue URI::InvalidURIError => e
      puts "error = #{e.to_s} at page #{@host_url}"
    rescue SocketError => e
      puts "error = #{e.to_s} at page #{@host_url}"
    rescue Zlib::BufError => e
      puts "error = #{e.to_s} at page #{@host_url}"
    end
    
    page_images.first rescue nil
  end

  def image_url
    return page_image.url.to_s rescue nil
  end
    
end