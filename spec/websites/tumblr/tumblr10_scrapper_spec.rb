require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../../websites/tumblr/tumblr10_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Tumblr10" do

  before(:each) do
    @url = YAML.load_file('private-conf/tumblr.yml')["tumblr10"]["url"]
    @tumblr10 = Tumblr10Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @tumblr10.home_page
    end

    describe "single_photo_links", :vcr => true do
      it "finds single images" do
        single_photo_links = @tumblr10.single_photo_links
        single_photo_links.count.should == 18

        expected_url = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr10"]["single_photo_links"]["image_source"]
        single_photo_links.first.should == expected_url
      end
    end

    describe "photoset_links", :vcr => true do
      it "finds images inside photoset" do
        photoset_links = @tumblr10.photoset_links
        photoset_links.count.should == 0
      end
    end
  end
end