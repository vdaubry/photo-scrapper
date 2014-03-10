require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/forum1'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Forum1", :local => :true do

  let(:category_name) { YAML.load_file('config/forums.yml')["forum1"]["category1"] }
  let(:date) { Date.parse("01/02/2010") }

  before(:each) do
    @url = YAML.load_file('config/forums.yml')["forum1"]["url"]
    @forum1 = Forum1.new(@url)
  end

  def go_to_home_page
    @forum1.home_page
  end

  def do_sign_in
    @user = YAML.load_file('config/forums.yml')["forum1"]["username"]
    @password = YAML.load_file('config/forums.yml')["forum1"]["password"]

    @forum1.sign_in(@user, @password)
  end

  let(:forum_page) do
    go_to_home_page
    do_sign_in
    forum_page = @forum1.category_forums(category_name)
    link = @forum1.forum_topics(forum_page).first
    forum_page.link_with(:href => link).click
  end

  describe "forum_topics", :vcr => true do
    it "returns all topics" do
      go_to_home_page
      forum_page = @forum1.current_page.link_with(:text => category_name).click
      @forum1.forum_topics(forum_page).count.should == 50
    end
  end

  describe "scrap_posts_from_category", :vcr => true do
    it "iterates on all categories" do
      go_to_home_page
      @forum1.expects(:scrap_post_hosted_images).times(50).returns(nil)

      @forum1.scrap_posts_from_category(category_name, date)
    end
  end

  describe "scrap_post_hosted_images", :vcr => true do
    context "calls post api" do
      it "creates a post" do
        forum_page.stubs(:title).returns("foobar_2010_January")
        PostApi.any_instance.expects(:create).with("52f7e1df4d61635e70010000", "foobar_2010_January").returns(Post.new({"id" => "6789"}))
        @forum1.stubs(:scrap_from_first_page).returns(nil)

        @forum1.scrap_post_hosted_images(forum_page, date)
      end

      it "sets post_image_count to 0" do
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        @forum1.stubs(:scrap_from_first_page).returns(nil)

        @forum1.scrap_post_hosted_images(forum_page, date)

        @forum1.post_images_count.should == 0      
      end

      it "destroys post if post_image_count is 0" do
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        @forum1.stubs(:scrap_from_first_page).returns(nil)
        @forum1.stubs(:post_images_count).returns(0)
        PostApi.any_instance.expects(:destroy).with("52f7e1df4d61635e70010000", "6789")
        
        @forum1.scrap_post_hosted_images(forum_page, date)
      end

      it "scrap post" do
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        @forum1.expects(:scrap_from_first_page).once.returns(nil)

        @forum1.scrap_post_hosted_images(forum_page, date)
      end
    end
  end

  describe "host_urls" do
    it "finds all images hosted urls", :vcr => true do
      @forum1.host_urls(forum_page).should == 20
    end
  end

  describe "scrap_from_first_page", :vcr => true do
    it "iterates on all urls" do

    end
  end
end