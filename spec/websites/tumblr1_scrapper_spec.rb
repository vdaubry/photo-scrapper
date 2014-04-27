require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/tumblr1_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Tumblr1" do

  before(:each) do
    @url = YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["url"]
    @tumblr1 = Tumblr1Scrapper.new(@url)
  end

  describe "unit tests", :local => :true do
    before(:each) do
      @tumblr1.home_page
    end

    describe "photoset_links", :vcr => true do
      it "finds images inside photoset" do
        photoset_links = @tumblr1.photoset_links
        photoset_links.count.should == 30

        expected_url = YAML.load_file('spec/websites/tumblr_test_conf.yml')["tumblr1"]["photoset_links"]["image_source"]
        photoset_links.first.should == expected_url
      end
    end

    describe "single_photo_links", :vcr => true do
      it "finds single images" do
        single_photo_links = @tumblr1.single_photo_links
        single_photo_links.count.should == 9

        expected_url = YAML.load_file('spec/websites/tumblr_test_conf.yml')["tumblr1"]["single_photo_links"]["image_source"]
        single_photo_links.first.should == expected_url
      end
    end

    describe "image_at_link", :vcr => true do
      it "finds photo" do
        image_src = YAML.load_file('spec/websites/tumblr_test_conf.yml')["tumblr1"]["single_photo_links"]["image_source"]
        image_link = YAML.load_file('spec/websites/tumblr_test_conf.yml')["tumblr1"]["image_at_link"]["image_link"]
        @tumblr1.image_at_link(image_link).should == image_src
      end
    end

    describe "do_scrap", :vcr => true do
      it "creates post" do
        @tumblr1.stubs(:download_image)
        post_name = YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["post_name"]
        Post.expects(:create).with(@tumblr1.id, post_name).once.returns(mock(:id => "123"))
        
        @tumblr1.do_scrap

        @tumblr1.post_id.should == "123"
      end

      it "downloads image" do
        image_src = YAML.load_file('spec/websites/tumblr_test_conf.yml')["tumblr1"]["do_scrap"]["image_source"]
        @tumblr1.expects(:download_image).with(image_src, nil).once
        @tumblr1.stubs(:download_image).with(Not(equals(image_src)), nil).times(38)

        @tumblr1.do_scrap
      end
    end
  end
end