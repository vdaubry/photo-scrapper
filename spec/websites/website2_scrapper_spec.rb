require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website2_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website2Scrapper", :local => :true do

  let(:date) { Date.parse("01/02/2000") }
  let(:excluded_urls) { YAML.load_file('private-conf/websites.yml')["website2"]["excluded_urls"] }
  let(:sample_page) {
    page_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website2"]["find_latest_pic"]["link"]
    Mechanize.new.get(page_url)
  }

  before(:each) do
    @url = YAML.load_file('private-conf/websites.yml')["website2"]["url"]
    @website2 = Website2Scrapper.new(@url)
  end

  describe "do_scrap", vcr: true do
    it "scraps allowed links" do
      @website2.expects(:scrap_allowed_links).once
      @website2.do_scrap
    end
  end

  def go_to_home_page
    @website2.home_page
  end

  describe "allowed_links", vcr: true do
    it "returns only linkqs to scrap" do
      go_to_home_page
      expected_urls = YAML.load_file('spec/websites/websites_test_conf.yml')["website2"]["allowed_links"]["expected_links"]

      @website2.allowed_links(excluded_urls).map(&:href).should =~ expected_urls
    end
  end

  describe "scrap_allowed_links", vcr: true do
    before(:each) do
      go_to_home_page
    end

    it "creates post" do
      Post.expects(:create).times(10).returns(Post.new({"id" => "123"}))
      @website2.stubs(:scrap_page).returns(nil)

      @website2.scrap_allowed_links(excluded_urls, date)
    end

    it "scraps each link" do
      Post.stubs(:create).returns(Post.new({"id" => "123"}))
      @website2.expects(:scrap_page).times(10).returns(nil)
      
      @website2.scrap_allowed_links(excluded_urls, date)
    end

    it "doesn't scrap links if post is banished" do
      Post.stubs(:create).returns(Post.new({"id" => "123", "banished" => true}))
      @website2.expects(:scrap_page).never
      
      @website2.scrap_allowed_links(excluded_urls, date)
    end
  end

  describe "scrap_page", vcr: true do
    it "downloads all found images" do
      @website2.expects(:download_image).times(1064).returns(nil)
      @website2.scrap_page(sample_page, date)
    end

    it "downloads image url" do
      @website2.expects(:download_image).at_least_once
      expected_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website2"]["expected_pic"]
      @website2.expects(:download_image).with(expected_url).once.returns(nil)
      @website2.scrap_page(sample_page, date)
    end

    it "ignores post with older dates" do
      @website2.stubs(:latest_pic_date).returns("01/01/1910")
      @website2.expects(:download_image).never
      @website2.scrap_page(sample_page, date)
    end
  end
end