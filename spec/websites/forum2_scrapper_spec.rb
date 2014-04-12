require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/forum2_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Forum2" do

  let(:category_name) { YAML.load_file('config/forums.yml')["forum2"]["category1"] }
  let(:date) { Date.parse("01/02/2010") }

  before(:each) do
    @url = YAML.load_file('config/forums.yml')["forum2"]["url"]
    @forum2 = Forum2Scrapper.new(@url)
  end

  def go_to_home_page
    @forum2.home_page
  end

  def do_sign_in
    @user = YAML.load_file('config/forums.yml')["forum2"]["username"]
    @password = YAML.load_file('config/forums.yml')["forum2"]["password"]

    @forum2.sign_in(@user, @password)
  end

  let(:forum_page) do
    post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["post_url"]
    @forum2.current_page = Mechanize.new.get(post_url)
    do_sign_in
    @forum2.current_page
  end

  describe "unit tests", :local => :true do

    describe "forum_topics", :vcr => true do
      it "returns all topics" do
        go_to_home_page
        do_sign_in

        forum_page = @forum2.current_page.link_with(:text => category_name).click
        @forum2.forum_topics(forum_page).count.should == 100
      end
    end

    describe "scrap_posts_from_category", :vcr => true do
      it "iterates on all categories" do
        go_to_home_page
        do_sign_in
        @forum2.expects(:scrap_post_hosted_images).times(100).returns(nil)

        @forum2.scrap_posts_from_category(category_name, date)
      end
    end

    describe "scrap_post_hosted_images", :vcr => true do
      context "calls post api" do
        it "creates a post" do
          forum_page.stubs(:title).returns("foobar_2010_January")
          Post.expects(:create).with("52f932da4d616302cf000000", "foobar_2010_January").returns(Post.new({"id" => "6789"}))
          @forum2.stubs(:scrap_from_page).returns(nil)

          @forum2.scrap_post_hosted_images(forum_page, date)
        end

        it "sets post_image_count to 0" do
          Post.stubs(:create).returns(Post.new({"id" => "6789"}))
          @forum2.stubs(:scrap_from_page).returns(nil)

          @forum2.scrap_post_hosted_images(forum_page, date)

          @forum2.post_images_count.should == 0      
        end

        it "destroys post if post_image_count is 0" do
          Post.stubs(:create).returns(Post.new({"id" => "6789"}))
          @forum2.stubs(:scrap_from_page).returns(nil)
          @forum2.stubs(:post_images_count).returns(0)
          Post.expects(:destroy).with("52f932da4d616302cf000000", "6789")
          
          @forum2.scrap_post_hosted_images(forum_page, date)
        end

        it "scrap post" do
          Post.stubs(:create).returns(Post.new({"id" => "6789"}))
          @forum2.expects(:scrap_from_page).once.returns(nil)

          @forum2.scrap_post_hosted_images(forum_page, date)
        end
      end
    end

    describe "host_urls", :vcr => true do
      it "finds all images hosted urls" do
        res = @forum2.host_urls(forum_page)
        res.count.should == 6
      end

      it "excludes snapshot from videos" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["host_urls"]["post_with_snaptshots"]
        @forum2.current_page = Mechanize.new.get(post_url)
        do_sign_in
        Image.stubs(:find_by).returns([])
        res = @forum2.host_urls(@forum2.current_page)
        
        res.count.should == 1
      end
    end

    describe "direct urls", :vcr => true do
      it "finds all direct images urls" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["scrap_from_page"]["tmp_hosted_post"]
        @forum2.current_page = Mechanize.new.get(post_url)
        do_sign_in
        res = @forum2.direct_urls(@forum2.current_page)
        res.count.should == 20
      end

      it "skips images that are links" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["post_url"]
        @forum2.current_page = Mechanize.new.get(post_url)
        do_sign_in
        res = @forum2.direct_urls(@forum2.current_page)
        res.count.should == 0
      end      
    end

    describe "page_image_at_host_url", :vcr => true do
      it "finds all images urls" do
        host_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["host_url"]
        expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["image_url"]
        @forum2.page_image_at_host_url(host_url).url.to_s.should == expected_image
      end

      it "returns nil if host is nil" do
        HostFactory.stubs(:create_with_host_url).returns(nil)
        @forum2.page_image_at_host_url("www.foo.bar").should == nil
      end
    end

    describe "scrap_from_page", :vcr => true do
      let(:fake_host_url) { YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["host_url"] }

      before(:each) do
        @forum2.stubs(:go_to_next_page).returns(nil)
      end

      it "scraps hosted images" do
        expected_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["image_url"]
        @forum2.stubs(:host_urls).returns([fake_host_url])
        @forum2.expects(:download_image).with(expected_image, anything).once.returns(nil)

        @forum2.scrap_from_page(forum_page, date)
      end

      it "skips images not found" do
        @forum2.stubs(:host_urls).returns([fake_host_url])
        @forum2.stubs(:page_image_at_host_url).returns(nil)
        @forum2.expects(:download_image).never

        @forum2.scrap_from_page(forum_page, date)
      end

      it "scraps direct images" do
        post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["scrap_from_page"]["tmp_hosted_post"]
        @forum2.current_page = Mechanize.new.get(post_url)
        do_sign_in
        tmp_hosted_image = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["scrap_from_page"]["tmp_hosted_image"]

        @forum2.expects(:download_image).with(tmp_hosted_image, nil).once
        @forum2.stubs(:download_image).with(Not(equals(tmp_hosted_image)), nil)

        @forum2.scrap_from_page(@forum2.current_page, date)
      end
    end

    describe "go_to_next_page", :vcr => true do
      context "not yet scrapped" do
        before(:each) do
          Post.stubs(:find_by).returns([])
        end

        let(:forum_page) do
          post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["go_to_next_page"]["post1_url"]
          @forum2.current_page = Mechanize.new.get(post_url)
          do_sign_in
          @forum2.current_page
        end        

        it "updates post pages_url" do
          expected_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum2"]["go_to_next_page"]["post2_url"]
          @forum2.post_id = "456"
          @forum2.stubs(:scrap_from_page).returns(nil)
          Post.expects(:update).with('52f932da4d616302cf000000', "456", expected_url)
          
          @forum2.go_to_next_page(forum_page, date)
        end

        it "scraps next page" do
          Post.stubs(:find_by).returns([])
          @forum2.expects(:scrap_from_page).once.returns(nil)
          Post.stubs(:update).returns(nil)
          
          @forum2.go_to_next_page(forum_page, date)
        end
      end

      context "already scrapped" do
        it "doesn't update post pages_url" do
          Post.stubs(:find_by).returns([Post.new({"id" => "6789"})])
          @forum2.expects(:scrap_from_page).never
          Post.expects(:update).never

          @forum2.go_to_next_page(forum_page, date)
        end
      end
    end
  end
end
