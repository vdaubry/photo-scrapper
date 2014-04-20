require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/forum5_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Forum5" do

  let(:category_name) { YAML.load_file('private-conf/forums.yml')["forum5"]["category1"] }
  let(:date) { Date.parse("01/02/2010") }

  before(:each) do
    @url = YAML.load_file('private-conf/forums.yml')["forum5"]["url"]
    @forum5 = Forum5Scrapper.new(@url)
  end

  def go_to_home_page
    @forum5.home_page
  end

  let(:forum_page) do
    post_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum5"]["post_url"]
    @forum5.current_page = Mechanize.new.get(post_url)
  end

  describe "unit tests", :local => :true do

    describe "forum_topics", :vcr => true do
      it "returns all topics" do
        go_to_home_page

        topic_page = @forum5.current_page.link_with(:text => category_name).click
        @forum5.forum_topics(topic_page).count.should == 50
      end
    end

    describe "scrap_posts_from_category", :vcr => true do
      it "iterates on all categories" do
        go_to_home_page
        @forum5.expects(:scrap_post_hosted_images).times(50).returns(nil)
        @forum5.scrap_posts_from_category(category_name, date)
      end
    end

    describe "host_urls", :vcr => true do
      it "finds all images hosted urls" do
        Image.stubs(:find_by).returns([])
        res = @forum5.host_urls(forum_page)
        res.count.should == 135
      end
    end

    describe "go_to_next_page", :vcr => true do
      context "not yet scrapped" do
        before(:each) do
          Post.stubs(:find_by).returns([])
        end

        it "finds next page" do
          expected_url = YAML.load_file('spec/websites/forums_test_conf.yml')["forum5"]["go_to_next_page"]["post_page2_url"]
          @forum5.post_id = "456"
          @forum5.stubs(:scrap_from_page).returns(nil)
          Post.expects(:update).with('534ace494d6163689e000000', "456", expected_url)
          
          @forum5.go_to_next_page(forum_page, date)
        end
      end
    end
  end
end
