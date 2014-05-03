require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/forum3_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Forum3" do

  let(:category_name) { YAML.load_file('private-conf/forums.yml')["forum3"]["category1"] }
  let(:date) { Date.parse("01/02/2010") }

  before(:each) do
    @url = YAML.load_file('private-conf/forums.yml')["forum3"]["url"]
    @forum3 = Forum3Scrapper.new(@url)
  end

  def go_to_home_page
    @forum3.home_page
  end

  def do_sign_in
    @user = YAML.load_file('private-conf/forums.yml')["forum3"]["username"]
    @password = YAML.load_file('private-conf/forums.yml')["forum3"]["password"]

    @forum3.sign_in(@user, @password)
  end

  let(:forum_page) do
    post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["post_url"]
    @forum3.current_page = Mechanize.new.get(post_url)
    do_sign_in
    @forum3.current_page
  end

  describe "unit tests", :local => :true do

    describe "forum_topics", :vcr => true do
      it "returns all topics" do
        go_to_home_page
        do_sign_in

        forum_page = @forum3.current_page.link_with(:text => category_name).click
        @forum3.forum_topics(forum_page).count.should == 68
      end
    end

    describe "scrap_posts_from_category", :vcr => true do
      it "iterates on all categories" do
        go_to_home_page
        do_sign_in
        @forum3.expects(:scrap_post_hosted_images).times(71).returns(nil)

        @forum3.scrap_posts_from_category(category_name, date)
      end
    end

    describe "scrap_post_hosted_images", :vcr => true do
      context "calls post api" do
        it "creates a post" do
          forum_page.stubs(:title).returns("foobar_2010_January")
          Post.expects(:create).with("52fd1d9a4d616303ef000000", "foobar_2010_January").returns(Post.new({"id" => "6789"}))
          @forum3.stubs(:scrap_from_page).returns(nil)

          @forum3.scrap_post_hosted_images(forum_page, date)
        end

        it "scrap post" do
          Post.stubs(:create).returns(Post.new({"id" => "6789"}))
          @forum3.expects(:scrap_from_page).once.returns(nil)

          @forum3.scrap_post_hosted_images(forum_page, date)
        end
      end
    end

    describe "host_urls", :vcr => true do
      it "finds all images hosted urls" do
        Image.stubs(:find_by).returns([])
        res = @forum3.host_urls(forum_page)
        res.count.should == 42
      end
    end

    describe "direct urls", :vcr => true do
      it "finds all direct images urls" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["scrap_from_page"]["tmp_hosted_post"]
        @forum3.current_page = Mechanize.new.get(post_url)
        do_sign_in
        res = @forum3.direct_urls(@forum3.current_page)
        res.count.should == 5
      end

      it "skips images that are links" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["post_url"]
        @forum3.current_page = Mechanize.new.get(post_url)
        do_sign_in
        res = @forum3.direct_urls(@forum3.current_page)
        res.count.should == 0
      end      
    end

    describe "scrap_from_page", :vcr => true do
      let(:fake_host_url) { YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["host_url"] }

      before(:each) do
        @forum3.stubs(:go_to_next_page).returns(nil)
      end

      it "scraps hosted images" do
        expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["host_url"]
        @forum3.stubs(:host_urls).returns([fake_host_url])
        @forum3.expects(:download_image).with(expected_image, anything).once.returns(nil)

        @forum3.scrap_from_page(forum_page, date)
      end

      it "scraps direct images" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["scrap_from_page"]["tmp_hosted_post"]
        @forum3.current_page = Mechanize.new.get(post_url)
        do_sign_in
        tmp_hosted_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["scrap_from_page"]["tmp_hosted_image"]

        @forum3.expects(:download_image).with(tmp_hosted_image, nil).once
        @forum3.stubs(:download_image).with(Not(equals(tmp_hosted_image)), nil)

        @forum3.scrap_from_page(@forum3.current_page, date)
      end
    end

    describe "go_to_next_page", :vcr => true do
      context "not yet scrapped" do
        before(:each) do
          Post.stubs(:find_by).returns([])
        end

        it "updates post pages_url" do
          expected_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum3"]["go_to_next_page"]["post_page2_url"]
          @forum3.post_id = "456"
          @forum3.stubs(:scrap_from_page).returns(nil)
          Post.expects(:update).with('52fd1d9a4d616303ef000000', "456", expected_url)
          
          @forum3.go_to_next_page(forum_page, date)
        end

        it "scraps next page" do
          Post.stubs(:find_by).returns([])
          @forum3.expects(:scrap_from_page).once.returns(nil)
          Post.stubs(:update).returns(nil)
          
          @forum3.go_to_next_page(forum_page, date)
        end
      end

      context "already scrapped" do
        it "doesn't update post pages_url" do
          Post.stubs(:find_by).returns([Post.new({"id" => "6789"})])
          @forum3.expects(:scrap_from_page).never
          Post.expects(:update).never

          @forum3.go_to_next_page(forum_page, date)
        end
      end
    end
  end
end
