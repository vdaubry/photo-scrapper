require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website1_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website1Scrapper", :local => :true do

  before(:each) do
    @url = YAML.load_file('private-conf/websites.yml')["website1"]["url"]
    @website1_scrapper = Website1Scrapper.new("website1", @url)
  end

  def go_to_home_page
    @website1_scrapper.home_page
  end

  def do_sign_in
    @user = YAML.load_file('private-conf/websites.yml')["website1"]["username"]
    @password = YAML.load_file('private-conf/websites.yml')["website1"]["password"]

    @website1_scrapper.sign_in(@user, @password)
  end

  def go_to_top_page
    go_to_home_page
    do_sign_in
    top_link = YAML.load_file('private-conf/websites.yml')["website1"]["top_link"]
    @website1_scrapper.top_page(top_link)
  end

  def go_to_category
    go_to_top_page
    @category_name = YAML.load_file('private-conf/websites.yml')["website1"]["category1"]
    @previous_month = Date.parse("01-02-2014")
    @website1_scrapper.category(@category_name, @previous_month)
  end

  describe "authorize", vcr: true do
    it "calls sign in" do
      @website1_scrapper.expects(:sign_in)
      @website1_scrapper.authorize
    end
  end

  describe "do_scrap", vcr: true do
    before(:each) do
      go_to_top_page
      @website1_scrapper.stubs(:category).returns("foo")
    end
    it "goes to top page" do
      @website1_scrapper.stubs(:scrap_category).returns("foo")
      @website1_scrapper.expects(:top_page).once
      @website1_scrapper.do_scrap
    end

    it "scraps all categories" do
      @website1_scrapper.expects(:scrap_category).times(12)
      @website1_scrapper.do_scrap
    end
  end

  describe "home_page", vcr: true do
    it "navigates to home_page" do
      go_to_home_page
      @website1_scrapper.current_page.content.should match /Log-in/
    end
  end

  describe "sign_in", vcr: true do
    it "post sign in form" do
      go_to_home_page
      do_sign_in
      @website1_scrapper.current_page.content.should match /#{@user}/
    end
  end

  describe "top_page", vcr: true do
    it "navigates to top page" do
      go_to_top_page
      @website1_scrapper.current_page.content.should match /Top of/
    end
  end

  describe "category", vcr: true do
    it "sets current post" do
      page = go_to_category
      page.title.should == "#{@category_name}_2014_February"
    end

    it "sets category on month and year" do
      page = go_to_category
      page.links_with(:class => "btn btn-success").map(&:text).should =~ ["2014", @category_name, "February"]
    end
  end

  describe "scrap_category", vcr: true do
    context "calls post api" do
      let(:month) { Date.parse("01/01/2010") }

      it "iterates on all links" do
        page = go_to_category
        @website1_scrapper.expects(:parse_image).times(100)
        @website1_scrapper.scrap_category(page, month)
      end
    end
  end

  describe "parse_image", vcr: true do
    let(:current_page) do 
      link_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website1"]["parse_image"]["link"]
      Mechanize.new.get(link_url)
    end
    let(:link) do 
      link_reg_exp = YAML.load_file('private-conf/websites.yml')["website1"]["link_reg_exp"]
      current_page.links_with(:href => %r{#{link_reg_exp}}).second
    end

    it "do nothing if no image on link" do
      @website1_scrapper.expects(:send_image_message).never
      @website1_scrapper.parse_image(link)
    end

    it "downloads found image" do
      image_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website1"]["parse_image"]["first_image"]
      @website1_scrapper.current_page = current_page
      do_sign_in

      @website1_scrapper.expects(:send_image_message).once
      @website1_scrapper.parse_image(link)
    end
  end
end