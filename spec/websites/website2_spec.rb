require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website2'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website2", :local => :true do

  let(:date) { Date.parse("01/02/2010") }
  let(:excluded_urls) { YAML.load_file('config/websites.yml')["website2"]["excluded_urls"] }
  let(:sample_page) {
    page_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website2"]["find_latest_pic"]["link"]
    Mechanize.new.get(page_url)
  }

  before(:each) do
    @url = YAML.load_file('config/websites.yml')["website2"]["url"]
    @website2 = Website2.new(@url)
  end

  describe "last_scrapping_date", vcr: true do
    context "has previous scrapping" do
      it "returns last scrapping date" do
        @website2.website = Website.new({"last_scrapping_date" => "01/02/2010"})
        @website2.last_scrapping_date.should == date
      end
    end

    context "has no previous scrapping" do
      it "returns 1 month ago" do
        Date.stubs(:now).returns(date)
        @website2.website = Website.new({"last_scrapping_date" => nil})
        @website2.last_scrapping_date.should == 1.month.ago.beginning_of_month
      end
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
      PostApi.any_instance.expects(:create).times(10).returns(Post.new({"id" => "123"}))
      @website2.stubs(:scrap_page).returns(nil)

      @website2.scrap_allowed_links(excluded_urls, date)
    end

    it "scraps each link" do
      PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "123"}))
      @website2.expects(:scrap_page).times(10).returns(nil)
      
      @website2.scrap_allowed_links(excluded_urls, date)
    end

    it "destroys post if post_image_count is 0" do
      @website2.stubs(:post_images_count).returns(0)
      PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "123"}))
      @website2.stubs(:scrap_page).returns(nil)
      PostApi.any_instance.expects(:destroy).with("52eea6be4d6163b84e000000", "123").times(10)
      
      @website2.scrap_allowed_links(excluded_urls, date)
    end
  end

  describe "find_latest_pic_date", vcr: true do
    it { @website2.find_latest_pic_date(sample_page).should == "2014-03-09" }
  end

  describe "images_links", vcr: true do
    it { @website2.images_links(sample_page).count.should == 106 }
  end

  describe "scrap_page", vcr: true do
    it "downloads found images" do
      @website2.expects(:download_image).times(106).returns(nil)
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
    it { @website2.lastpid(sample_page).should == "915378" }
  end

  describe "go_to_next_page", vcr: true do
    it "gets next page" do
      post_url = YAML.load_file('config/websites.yml')["website2"]["post_url"]
      Mechanize.any_instance.expects(:post).with(post_url, {"req" => "morepics", "cid" => "601553", "lastpid" => "915378"})
      @website2.stubs(:scrap_page).returns(nil)
      @website2.go_to_next_page(sample_page, date)
    end

    it "scraps next page" do
      mock_page = mock()
      date = Date.parse("01/02/2010")
      Mechanize.any_instance.stubs(:post).returns(mock_page)
      @website2.expects(:scrap_page).with(mock_page, date).once

      @website2.go_to_next_page(sample_page, date)
    end
  end
end