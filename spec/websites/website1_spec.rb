require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'

describe "Website1", :local => :true do

  before(:each) do
    @url = YAML.load_file('config/websites.yml')["website1"]["url"]
    @website = Website1.new(@url)
  end

  describe "home_page", vcr: true do
    it "navigates to home_page" do
      @website.home_page.should_not be_nil
    end
  end

  describe "sign_in", vcr: true do
    it "post sign in form" do
      @website.home_page
      user = YAML.load_file('config/websites.yml')["website1"]["username"]
      password = YAML.load_file('config/websites.yml')["website1"]["password"]

      @website.sign_in(user, password)
      @website.current_page.content.should match /#{user}/
    end
  end

  describe "top_page", vcr: true do
    it "navigates to top page" do
      @website.home_page
      top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
      @website.top_page(top_link)
      @website.current_page.content.should match /Top of/
    end
  end


end