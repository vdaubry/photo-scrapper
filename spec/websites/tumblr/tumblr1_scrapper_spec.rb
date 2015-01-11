require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../../websites/tumblr/tumblr1_scrapper'

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
        photoset_links.count.should == 83

        expected_url = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr1"]["photoset_links"]["image_source"]
        photoset_links.first.should == expected_url
      end
    end

    describe "single_photo_links", :vcr => true do
      it "finds single images" do
        single_photo_links = @tumblr1.single_photo_links
        single_photo_links.count.should == 4

        #expected_url = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr1"]["single_photo_links"]["image_source"]
        #single_photo_links.first.should == expected_url
      end
    end

    describe "image_at_link", :vcr => true do
      it "finds photo" do
        image_src = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr1"]["single_photo_links"]["image_source"]
        image_link = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr1"]["image_at_link"]["image_link"]
        @tumblr1.image_at_link(image_link).should == image_src
      end
    end

    describe "do_scrap", :vcr => true do
      
      context "has not downloaded next page" do
        before(:each) do
          @tumblr1.stubs(:go_to_next_page)
        end
        
        it "creates post" do
          @tumblr1.stubs(:download_image)
          post_name = YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["post_name"]
          Post.expects(:create).with(@tumblr1.id, post_name).once.returns(Post.new({"id" => "123", "banished" => false}))
          
          @tumblr1.do_scrap

          @tumblr1.post_id.should == "123"
        end

        it "doesn't creates post" do
          Post.stubs(:create).returns(Post.new({"id" => "6789", "banished" => true}))
          
          @tumblr1.do_scrap

          @tumblr1.expects(:download_image).never
        end

        it "downloads image" do
          image_src = YAML.load_file('spec/websites/tumblr/tumblr_test_conf.yml')["tumblr1"]["do_scrap"]["image_source"]
          @tumblr1.expects(:download_image).with(image_src).once
          @tumblr1.stubs(:download_image).with(Not(equals(image_src))).times(86)

          @tumblr1.do_scrap
        end
      end
      
      context "has downloaded next page" do
        it "stops if an already downloaded image is found" do
          @tumblr1.stubs(:download_image).returns(false)
          @tumblr1.do_scrap
          @tumblr1.expects(:go_to_next_page).never
        end
      end
    end

    describe "go_to_next_page", :vcr => true do
      before(:each) do
        @tumblr1.post_id = "123"
        @tumblr1.stubs(:do_scrap).returns(nil)
      end

      context "2nd page not scrapped" do
        before(:each) do
          Post.stubs(:find_by).returns(nil)
        end

        it "stops if no more pages" do
          @tumblr1.current_page = Mechanize.new.get("#{@url}/page/200")
          Post.expects(:update).never
          @tumblr1.go_to_next_page
        end

        context "page doesn't exist" do
          it "catches error" do
            page = mock("Mechanize::Page")
            page.stubs(:code).returns(404)
            Mechanize.any_instance.stubs(:get).raises(Mechanize::ResponseCodeError.new(page))
            @tumblr1.go_to_next_page
          end
        end
      end
    end
  end
end 