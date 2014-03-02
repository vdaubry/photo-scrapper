require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'

describe "Website1", :local => :true do

  before(:each) do
    @url = YAML.load_file('config/websites.yml')["website1"]["url"]
    @website = Website1.new(@url)
  end

  def go_to_home_page
    @website.home_page
  end

  def do_sign_in
    go_to_home_page
    @user = YAML.load_file('config/websites.yml')["website1"]["username"]
    @password = YAML.load_file('config/websites.yml')["website1"]["password"]

    @website.sign_in(@user, @password)
  end

  def go_to_top_page
    do_sign_in
    top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
    @website.top_page(top_link)
  end

  describe "home_page", vcr: true do
    it "navigates to home_page" do
      go_to_home_page
      @website.current_page.content.should match /Log-in/
    end
  end

  describe "sign_in", vcr: true do
    it "post sign in form" do
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

  describe "scrap_category", vcr: true do
    before(:each) do
      go_to_top_page
      @category_name = YAML.load_file('config/websites.yml')["website1"]["category1"]
      @previous_month = Date.parse("01-02-2014")
      @website.stubs(:download_image).returns(nil)
    end

    it "sets current post" do
      @website.scrap_category(@category_name, @previous_month)
      @website.current_post.should == "#{@category_name}_2014_February"
    end

    it "iterates on all links" do
      @website.expects(:download_image).times(100)
      @website.scrap_category(@category_name, @previous_month)
    end
  end
end