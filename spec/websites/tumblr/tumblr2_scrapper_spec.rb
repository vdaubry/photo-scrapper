require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../../websites/tumblr/tumblr2_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Tumblr2" do

  before(:each) do
    @url = YAML.load_file('private-conf/tumblr.yml')["tumblr2"]["url"]
    @tumblr2 = Tumblr2Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @tumblr2.home_page
    end

    describe "single_photo_links", :vcr => true do
      it "finds single images" do
        single_photo_links = @tumblr2.single_photo_links
        single_photo_links.count.should == 15

        expected_url = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr2"]["single_photo_links"]["image_source"]
        single_photo_links.first.should == expected_url
      end
    end

    describe "is_current_page_last_page", :vcr => true do
      context "is not at last page" do
        before(:each) do
          @tumblr2.current_page = Mechanize.new.get("#{@url}/page/3")
        end

        it { @tumblr2.is_current_page_last_page.should == false }
      end

      context "is at last page" do
        before(:each) do
          @tumblr2.current_page = Mechanize.new.get("#{@url}/page/200")
        end

        it { @tumblr2.is_current_page_last_page.should == true }
      end
    end
  end
end