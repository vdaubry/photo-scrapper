require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/tumblr1_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Tumblr1" do

  before(:each) do
    @url = YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["url"]
    @tumblr1 = Tumblr1Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @tumblr1.home_page
    end

    describe "image_links", :vcr => true do
      it "finds photo" do
        @tumblr1.image_links.count.should == 39
      end
    end

    describe "do_scrap", :vcr => true do
      it "downloads photo" do
        @tumblr1.expects(:download_image).times(39)
        @tumblr1.do_scrap
      end
    end
  end
end