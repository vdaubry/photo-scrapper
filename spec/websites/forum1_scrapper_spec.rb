require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/forum1_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Forum1" do

  let(:category_name) { YAML.load_file('private-conf/forums.yml')["forum1"]["category1"] }
  let(:date) { Date.parse("01/02/2010") }

  before(:each) do
    @url = YAML.load_file('private-conf/forums.yml')["forum1"]["url"]
    @forum1 = Forum1Scrapper.new(@url)
  end

  def go_to_home_page
    @forum1.home_page
  end

  def do_sign_in
    @user = YAML.load_file('private-conf/forums.yml')["forum1"]["username"]
    @password = YAML.load_file('private-conf/forums.yml')["forum1"]["password"]

    @forum1.sign_in(@user, @password)
  end

  let(:forum_page) do
    post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["post_url"]
    Mechanize.new.get(post_url)
  end

  describe "unit tests", :local => :true do

    describe "forum_topics", :vcr => true do
      before(:each) do
        go_to_home_page
        @topics_page = @forum1.current_page.link_with(:text => category_name).click
      end

      it "returns all topics" do
        @forum1.forum_topics(@topics_page).count.should == 50
      end

      it "returns multiple page topics" do
        expected_topic = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["forum_topics"]["multiple_page_topic"]
        @forum1.forum_topics(@topics_page).should include(expected_topic)
      end

      it "returns single page topics" do
        expected_topic = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["forum_topics"]["single_page_topic"]
        @forum1.forum_topics(@topics_page).should include(expected_topic)
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
          Post.expects(:create).with("52f7e1df4d61635e70010000", "foobar_2010_January").returns(Post.new({"id" => "6789"}))
          @forum1.stubs(:scrap_from_page).returns(nil)

          @forum1.scrap_post_hosted_images(forum_page, date)
        end

        it "scrap post" do
          Post.stubs(:create).returns(Post.new({"id" => "6789"}))
          @forum1.expects(:scrap_from_page).once.returns(nil)

          @forum1.scrap_post_hosted_images(forum_page, date)
        end
      end
    end

    describe "host_urls", :vcr => true do
      it "finds all images hosted urls", :vcr => true do
        res = @forum1.host_urls(forum_page)
        res.count.should == 1
      end

      it "reject images on postimage", :vcr => true do
        forum_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_urls"]["hotlink_image"]
        forum_page = Mechanize.new.get(forum_url)
        res = @forum1.host_urls(forum_page)
        res.count.should == 0
      end
    end

    describe "direct_urls", :vcr => true do
      it "finds all gotlink images" do
        forum_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_urls"]["hotlink_image"]
        forum_page = Mechanize.new.get(forum_url)
        res = @forum1.direct_urls(forum_page)
        res.count.should == 10
      end
    end

    describe "page_image_at_host_url", :vcr => true do
      it "finds all images urls" do
        host_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_url"]
        expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["image_url"]
        @forum1.page_image_at_host_url(host_url).url.to_s.should == expected_image
      end
    end

    describe "scrap_from_page", :vcr => true do
      let(:fake_host_url) { YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_url"] }

      it "iterates on all urls" do
        expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["image_url"]
        @forum1.stubs(:host_urls).returns([fake_host_url])
        @forum1.expects(:download_image).with(expected_image, anything).once.returns(nil)

        @forum1.scrap_from_page(forum_page, date)
      end

      it "skips images not found" do
        @forum1.stubs(:host_urls).returns([fake_host_url])
        @forum1.stubs(:page_image_at_host_url).returns(nil)
        @forum1.expects(:download_image).never

        @forum1.scrap_from_page(forum_page, date)
      end

      it "scraps images hosted on forum" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["scrap_from_page"]["wbw_hosted_post"]
        @forum1.current_page = Mechanize.new.get(post_url)
        do_sign_in
        wbw_hosted_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["scrap_from_page"]["wbw_hosted_image"]

        @forum1.expects(:download_image).with(wbw_hosted_image, nil)
        @forum1.stubs(:download_image).with(Not(equals(wbw_hosted_image)), nil)
        
        @forum1.scrap_from_page(@forum1.current_page, date)
      end

      it "scraps images hotlinked on forum" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["host_urls"]["hotlink_image"]
        @forum1.current_page = Mechanize.new.get(post_url)
        hotlinked_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["scrap_from_page"]["hotlinked_image"]
        @forum1.stubs(:go_to_next_page).returns(nil)

        @forum1.expects(:download_image).with(hotlinked_image, nil)
        @forum1.stubs(:download_image).with(Not(equals(hotlinked_image)), nil)
        
        @forum1.scrap_from_page(@forum1.current_page, date)
      end      
    end

    describe "go_to_next_page", :vcr => true do
      let(:last_page) { Mechanize.new.get(YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["go_to_next_page"]["post_page_5_url"]) }

      context "not yet scrapped" do
        before(:each) do
          Post.stubs(:find_by).returns([])
        end

        it "updates post pages_url" do
          expected_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["go_to_next_page"]["post_page_4_url"]
          @forum1.post_id = "456"
          @forum1.stubs(:scrap_from_page).returns(nil)
          Post.expects(:update).with('52f7e1df4d61635e70010000', "456", expected_url)
          
          @forum1.go_to_next_page(last_page, date)
        end

        it "scraps next page" do
          Post.stubs(:find_by).returns([])
          @forum1.expects(:scrap_from_page).once.returns(nil)
          Post.stubs(:update).returns(nil)
          
          @forum1.go_to_next_page(last_page, date)
        end
      end

      context "already scrapped" do
        it "doesn't update post pages_url" do
          Post.stubs(:find_by).returns([Post.new({"id" => "6789"})])
          @forum1.expects(:scrap_from_page).never
          Post.expects(:update).never

          @forum1.go_to_next_page(last_page, date)
        end
      end
    end
  end

  describe "integration test", :integration => :true do
    describe "Host2", :vcr => true do

      it "scraps images protected by hotlinking" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum1"]["scrap_from_page"]["host_error_post"]
        @forum1.current_page = Mechanize.new.get(post_url)
        do_sign_in

        Image.stubs(:find_by).returns([])
        Image.expects(:create).times(107).with(anything, anything, anything, anything, anything, anything, Not(equals("42492684e24356a4081134894eabeb9e")), anything, anything, anything)

        @forum1.scrap_from_page(@forum1.current_page, date)
      end
    end
  end
end
