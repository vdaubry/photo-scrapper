require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../../websites/tumblr/tumblr11_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Tumblr11" do

  before(:each) do
    @url = YAML.load_file('private-conf/tumblr.yml')["tumblr11"]["url"]
    @tumblr11 = Tumblr11Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @tumblr11.home_page
    end

    describe "single_photo_links", :vcr => true do
      it "finds single images" do
        single_photo_links = @tumblr11.single_photo_links
        single_photo_links.count.should == 11

        expected_url = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr11"]["single_photo_links"]["image_source"]
        single_photo_links.first.should == expected_url
      end
    end

    describe "photoset_links", :vcr => true do
      it "finds images inside photoset" do
        photoset_links = @tumblr11.photoset_links
        photoset_links.count.should == 17
      end
    end
  end
end