require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website1'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website1", :local => :true do

  before(:each) do
    @url = YAML.load_file('config/websites.yml')["website1"]["url"]
    @website1 = Website1.new(@url)
  end

  def go_to_home_page
    @website1.home_page
  end

  def do_sign_in
    @user = YAML.load_file('config/websites.yml')["website1"]["username"]
    @password = YAML.load_file('config/websites.yml')["website1"]["password"]

    @website1.sign_in(@user, @password)
  end

  def go_to_top_page
    go_to_home_page
    do_sign_in
    top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
    @website1.top_page(top_link)
  end

  def go_to_category
    go_to_top_page
    @category_name = YAML.load_file('config/websites.yml')["website1"]["category1"]
    @previous_month = Date.parse("01-02-2014")
    @website1.category(@category_name, @previous_month)
  end

  describe "initialize", vcr: true do
    
    context "API return websites" do
      it "sets website" do
        result = Website.new({"id" => "12345"})
        WebsiteApi.any_instance.stubs(:search).with(@url).returns([result])

        websites = Website1.new(@url)

        websites.website.should == result
      end
    end

    context "API return error" do
      it "sets website" do
        result = Website.new({"id" => "12345"})
        WebsiteApi.any_instance.stubs(:search).with(@url).returns(nil)

        expect {
          Website1.new(@url)
          }.to raise_error(RuntimeError)
      end
    end
  end

  describe "home_page", vcr: true do
    it "navigates to home_page" do
      go_to_home_page
      @website1.current_page.content.should match /Log-in/
    end
  end

  describe "previous_month", vcr: true do
    context "has last scrapping date" do
      it "returns 1 month before last scrapping date" do
        @website1.website = Website.new({"last_scrapping_date" => "01/02/2010"})
        @website1.previous_month.should == Date.parse("01/01/2010")
      end
    end
  end

  describe "next_month", vcr: true do
    context "has last scrapping date" do
      it "returns 1 month after last scrapping date" do
        @website1.website = Website.new({"last_scrapping_date" => "01/02/2010"})
        @website1.next_month.should == Date.parse("01/03/2010")
      end
    end
  end

  describe "sign_in", vcr: true do
    it "post sign in form" do
      go_to_home_page
      do_sign_in
      @website1.current_page.content.should match /#{@user}/
    end
  end

  describe "top_page", vcr: true do
    it "navigates to top page" do
      go_to_top_page
      @website1.current_page.content.should match /Top of/
    end
  end

  describe "category", vcr: true do
    it "sets current post" do
      go_to_category
      @website1.current_post_name.should == "#{@category_name}_2014_February"
    end

    it "sets category on month and year" do
      page = go_to_category
      page.links_with(:class => "btn btn-success").map(&:text).should =~ ["2014", @category_name, "February"]
    end
  end

  describe "scrap_category", vcr: true do
    context "calls post api" do
      let(:month) { Date.parse("01/01/2010") }
      let(:website1) do
        @website1.website = Website.new({"id" => "12345", "last_scrapping_date" => "01/02/2010", "url" => "www.foo.bar"})
        @website1.current_post_name = "foobar_2010_January"
        @website1.stubs(:parse_image).returns(nil)
        
        @website1
      end

      it "creates a post" do
        page = go_to_category
        PostApi.any_instance.expects(:create).with("12345", "foobar_2010_January").returns(Post.new({"id" => "6789"}))

        website1.scrap_category(page, month)
      end

      it "destroys post if post_image_count is 0" do
        page = go_to_category
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        website1.stubs(:post_images_count).returns(0)
        PostApi.any_instance.expects(:destroy).with("12345", "6789")
        
        website1.scrap_category(page, month)
      end

      it "sets post_image_count to 0" do
        page = go_to_category
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        website1.scrap_category(page, month)

        website1.post_images_count.should == 0      
      end

      it "iterates on all links" do
        page = go_to_category
        PostApi.any_instance.stubs(:create).returns(Post.new({"id" => "6789"}))
        website1.expects(:parse_image).times(100)
        website1.scrap_category(page, month)
      end
    end
  end

  describe "parse_image", vcr: true do
    let(:current_page) do 
      link_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website1"]["parse_image"]["link"]
      Mechanize.new.get(link_url)
    end
    let(:link) do 
      link_reg_exp = YAML.load_file('config/websites.yml')["website1"]["link_reg_exp"]
      current_page.link_with(:href => %r{#{link_reg_exp}})#[0..1]
    end

    it "do nothing if no image on link" do
      ImageApi.any_instance.stubs(:search).returns([Image.new({"key" => "image_key"})])
      ImageDownloader.any_instance.expects(:download).never
      @website1.parse_image(link)
    end

    it "downloads found image" do
      image_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website1"]["parse_image"]["first_image"]
      ImageApi.any_instance.stubs(:search).with('52ee82a14d6163a27e000000', image_url).returns([])
      @website1.current_page = current_page
      do_sign_in

      ImageDownloader.any_instance.expects(:download).once
      @website1.parse_image(link)
    end

    context "Search API failure" do
      it "do nothing if no image on link" do
        ImageApi.any_instance.stubs(:search).returns(nil)
        ImageDownloader.any_instance.expects(:download).never
        @website1.parse_image(link)
      end
    end
  end

  describe "download_image", vcr: true do
    let(:url) { "www.foo.bar/image.png" }

    before(:each) do
      @website1.website = Website.new({"id" => "123", "last_scrapping_date" => "01/02/2010", "url" => "www.foo.bar"})
      @website1.post_id = "456"
      ImageApi.any_instance.stubs(:search).returns([])
    end

    it "downloads image" do
      mock = ImageDownloader.new("key")
      mock.expects(:download).once
      ImageDownloader.any_instance.expects(:build_info).with("123", "456", url).returns(mock)

      @website1.download_image(url)
    end

    context "download image ok" do
      it "increases post_images_count" do
        @website1.post_images_count = 0
        ImageDownloader.any_instance.expects(:download).returns(true)

        @website1.download_image(url)

        @website1.post_images_count.should == 1
      end
    end

    context "download image ko" do
      it "doesn't increase post_images_count" do
        @website1.post_images_count = 0
        ImageDownloader.any_instance.expects(:download).returns(false)

        @website1.download_image(url)

        @website1.post_images_count.should == 0
      end
    end
  end
end