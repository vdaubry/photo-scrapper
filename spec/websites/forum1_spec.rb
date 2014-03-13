require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/forum1'
require_relative '../../models/post_api'

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
    post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["post_url"]
    Mechanize.new.get(post_url)
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
        @forum1.stubs(:scrap_from_page).returns(nil)

        @forum1.scrap_post_hosted_images(forum_page, date)
      end

      it "sets post_image_count to 0" do
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        @forum1.stubs(:scrap_from_page).returns(nil)

        @forum1.scrap_post_hosted_images(forum_page, date)

        @forum1.post_images_count.should == 0      
      end

      it "destroys post if post_image_count is 0" do
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        @forum1.stubs(:scrap_from_page).returns(nil)
        @forum1.stubs(:post_images_count).returns(0)
        PostApi.any_instance.expects(:destroy).with("52f7e1df4d61635e70010000", "6789")
        
        @forum1.scrap_post_hosted_images(forum_page, date)
      end

      it "scrap post" do
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        @forum1.expects(:scrap_from_page).once.returns(nil)

        @forum1.scrap_post_hosted_images(forum_page, date)
      end
    end
  end

  describe "host_urls" do
    it "finds all images hosted urls", :vcr => true do
      res = @forum1.host_urls(forum_page)

      puts "#{res.first}"
      puts "#{res.last}"

      res.count.should == 1
    end
  end

  describe "page_image_at_host_url", :vcr => true do
    it "finds all images urls" do
      host_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_url"]
      expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["image_url"]
      @forum1.page_image_at_host_url(host_url).should == expected_image
    end
  end

  describe "scrap_from_page", :vcr => true do
    let(:fake_host_url) { YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_url"] }

    it "iterates on all urls" do
      expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["image_url"]
      @forum1.stubs(:host_urls).returns([fake_host_url])
      @forum1.expects(:download_image).with(expected_image).once.returns(nil)

      @forum1.scrap_from_page(forum_page, date)
    end

    it "skips images not found" do
      @forum1.stubs(:host_urls).returns([fake_host_url])
      @forum1.stubs(:page_image_at_host_url).returns(nil)
      @forum1.expects(:download_image).never

      @forum1.scrap_from_page(forum_page, date)
    end

    it "pases images hosted on forum" do
      post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["scrap_from_page"]["wbw_hosted_post"]
      @forum1.current_page = Mechanize.new.get(post_url)
      do_sign_in
      wbw_hosted_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["scrap_from_page"]["wbw_hosted_image"]
      @forum1.expects(:download_image).with(wbw_hosted_image).once
      @forum1.stubs(:download_image).with(Not(equals(wbw_hosted_image)))

      @forum1.scrap_from_page(@forum1.current_page, date)
    end
  end

  describe "go_to_next_page", :vcr => true do
    context "not yet scrapped" do
      before(:each) do
        PostApi.any_instance.stubs(:search).returns([])
      end

      it "updates post pages_url" do
        expected_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["go_to_next_page"]["post2_url"]
        @forum1.post_id = "456"
        @forum1.stubs(:scrap_from_page).returns(nil)
        PostApi.any_instance.expects(:update).with('52f7e1df4d61635e70010000', "456", expected_url)
        
        @forum1.go_to_next_page(forum_page, date)
      end

      it "scraps next page" do
        PostApi.any_instance.stubs(:search).returns([])
        @forum1.expects(:scrap_from_page).once.returns(nil)
        PostApi.any_instance.stubs(:update).returns(nil)
        
        @forum1.go_to_next_page(forum_page, date)
      end
    end

    context "already scrapped" do
      it "doesn't update post pages_url" do
        PostApi.any_instance.stubs(:search).returns([Post.new({"id" => "6789"})])
        @forum1.expects(:scrap_from_page).never
        PostApi.any_instance.expects(:update).never

        @forum1.go_to_next_page(forum_page, date)
      end
    end
  end
end