require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website1'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website1", :local => :true do

  before(:each) do
    @url = YAML.load_file('config/websites.yml')["website1"]["url"]
    @website = Website1.new(@url)
  end

  def go_to_home_page
    @website.home_page
  end

  def do_sign_in
    @user = YAML.load_file('config/websites.yml')["website1"]["username"]
    @password = YAML.load_file('config/websites.yml')["website1"]["password"]

    @website.sign_in(@user, @password)
  end

  def go_to_top_page
    go_to_home_page
    do_sign_in
    top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
    @website.top_page(top_link)
  end

  def go_to_category
    go_to_top_page
    @category_name = YAML.load_file('config/websites.yml')["website1"]["category1"]
    @previous_month = Date.parse("01-02-2014")
    @website.category(@category_name, @previous_month)
  end

  describe "home_page", vcr: true do
    it "navigates to home_page" do
      go_to_home_page
      @website.current_page.content.should match /Log-in/
    end
  end

  describe "sign_in", vcr: true do
    it "post sign in form" do
      go_to_home_page
      do_sign_in
      @website.current_page.content.should match /#{@user}/
    end
  end

  describe "top_page", vcr: true do
    it "navigates to top page" do
      go_to_top_page
      @website.current_page.content.should match /Top of/
    end
  end

  describe "category", vcr: true do
    it "sets current post" do
      go_to_category
      @website.current_post.should == "#{@category_name}_2014_February"
    end

    it "sets category on month and year" do
      page = go_to_category
      page.links_with(:class => "btn btn-success").map(&:text).should =~ ["2014", @category_name, "February"]
    end
  end

  describe "scrap_category", vcr: true do
    it "iterates on all links" do
      page = go_to_category
      @website.expects(:parse_image).times(100)
      @website.scrap_category(page)
    end
  end

  describe "parse_image", vcr: true do
    let(:current_page) do 
      link_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website1"]["parse_image"]["link"]
      Mechanize.new.get(link_url)
    end
    let(:link) do 
      link_reg_exp = YAML.load_file('config/websites.yml')["website1"]["link_reg_exp"]
      current_page.link_with(:href => %r{#{link_reg_exp}})#[0..1]
    end

    it "do nothing if no image on link" do
      ImageApi.any_instance.stubs(:search).returns([{:key => "image_key"}])
      @website.expects(:download_image).never
      @website.parse_image(link)
    end

    it "downloads found image" do
      ImageApi.any_instance.stubs(:search).returns([])
      @website.current_page = current_page
      do_sign_in

      @website.expects(:download_image).once
      @website.parse_image(link)
    end    
  end
end