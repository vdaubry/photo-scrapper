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

  let(:date) { Date.parse("01/02/2010") }
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

  describe "find_latest_pic_date", vcr: true do
    it { @website2.find_latest_pic_date(sample_page).should == "2014-04-16" }
  end

  describe "images_links", vcr: true do
    it { @website2.images_links(sample_page).count.should == 100 }
  end

  describe "scrap_page", vcr: true do
    it "downloads found images" do
      @website2.expects(:download_image).times(100).returns(nil)
      @website2.stubs(:go_to_next_page).returns(nil)
      
      @website2.scrap_page(sample_page, date )
    end

    it "goes to next page" do
      @website2.stubs(:download_image).returns(nil)
      @website2.expects(:go_to_next_page)
      
      @website2.scrap_page(sample_page, date)
    end

    it "ignores post with older dates" do
      @website2.stubs(:find_latest_pic_date).returns("01/01/2010")
      @website2.expects(:images_links).never

      @website2.scrap_page(sample_page, date)
    end

    it "scraps images after current scrapping date" do
      @website2.stubs(:find_latest_pic_date).returns("01/02/2010")
      @website2.stubs(:go_to_next_page).returns(nil)
      @website2.expects(:images_links).once.returns([])

      @website2.scrap_page(sample_page, date)
    end
  end

  describe "next_page_button", vcr: true do
    it { @website2.next_page_button(sample_page).attributes["id"].value.should == "mp_button" }
  end

  describe "model_id", vcr: true do
    it { @website2.model_id(sample_page).should == "601553" }
  end

  describe "lastpid", vcr: true do
    it { @website2.lastpid(sample_page).should == "1037314" }
  end

  describe "go_to_next_page", vcr: true do
    before(:each) do
      @website2.has_next_page = true
      @website2.model_id = "601553"
    end

    it "gets next page" do
      post_url = YAML.load_file('private-conf/websites.yml')["website2"]["post_url"]
      mock_page = stub(:content => "</div>|815|976002")
      Mechanize.any_instance.expects(:post).with(post_url, {"req" => "morepics", "cid" => "601553", "lastpid" => "1037314"}).returns(mock_page)
      @website2.stubs(:scrap_page).returns(nil)
      
      @website2.go_to_next_page(sample_page, date)
    end

    it "scraps next page" do
      mock_page = stub(:content => "</div>|815|976002")
      date = Date.parse("01/02/2010")
      Mechanize.any_instance.stubs(:post).returns(mock_page)
      @website2.expects(:scrap_page).with(mock_page, date).once

      @website2.go_to_next_page(sample_page, date)
    end
  end
end