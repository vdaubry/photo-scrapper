require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../../websites/tumblr/tumblr3_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Tumblr3" do

  before(:each) do
    @url = YAML.load_file('private-conf/tumblr.yml')["tumblr3"]["url"]
    @tumblr3 = Tumblr3Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @tumblr3.home_page
    end

    describe "single_photo_links", :vcr => true do
      it "finds single images" do
        single_photo_links = @tumblr3.single_photo_links
        single_photo_links.count.should == 9

        expected_url = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr3"]["single_photo_links"]["image_source"]
        single_photo_links.first.should == expected_url
      end
    end
  end
end