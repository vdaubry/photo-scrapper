require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website3_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website3" do

  before(:each) do
    @url = YAML.load_file('private-conf/websites.yml')["website3"]["url"]
    @website3 = Website3Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @website3.home_page
    end

    describe "links", :vcr => true do
      it "finds all links to scrap" do
        links = @website3.links
        links.count.should == 100
        
        @website3.links.first.uri.to_s.should == "/posts/7160"
      end
    end
    
    describe "images_urls", :vcr => true do
      it "finds all images url inside page" do
        url = YAML.load_file('spec/websites/websites_test_conf.yml')["website3"]["link"]
        page = Mechanize.new.get(url)
        
        urls = @website3.images_urls(page)
        urls.count.should == 52
        
        expected_image_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website3"]["image_url"]
        urls.first.should == expected_image_url
      end
    end
    
    describe "next_page_url", :vcr => true do
      it "gets url of next page" do
        expected_page_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website3"]["next_page_url"]
        @website3.next_page_url(2).should == expected_page_url
      end
    end
  end
end