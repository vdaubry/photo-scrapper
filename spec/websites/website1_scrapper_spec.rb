require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'spec_helper'
require_relative '../../websites/website1_scrapper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Website1Scrapper", :local => :true do

  before(:each) do
    @url = YAML.load_file('private-conf/websites.yml')["website1"]["url"]
    @website1_scrapper = Website1Scrapper.new(@url)
  end

  def go_to_home_page
    @website1_scrapper.home_page
  end

  def do_sign_in
    @user = YAML.load_file('private-conf/websites.yml')["website1"]["username"]
    @password = YAML.load_file('private-conf/websites.yml')["website1"]["password"]

    @website1_scrapper.sign_in(@user, @password)
  end

  def go_to_top_page
    go_to_home_page
    do_sign_in
    top_link = YAML.load_file('private-conf/websites.yml')["website1"]["top_link"]
    @website1_scrapper.top_page(top_link)
  end

  def go_to_category
    go_to_top_page
    @category_name = YAML.load_file('private-conf/websites.yml')["website1"]["category1"]
    @previous_month = Date.parse("01-02-2014")
    @website1_scrapper.category(@category_name, @previous_month)
  end

  describe "authorize", vcr: true do
    it "calls sign in" do
      @website1_scrapper.expects(:sign_in)
      @website1_scrapper.authorize
    end
  end

  describe "do_scrap", vcr: true do
    before(:each) do
      go_to_top_page
      @website1_scrapper.stubs(:category).returns("foo")
    end
    it "goes to top page" do
      @website1_scrapper.stubs(:scrap_category).returns("foo")
      @website1_scrapper.expects(:top_page).once
      @website1_scrapper.do_scrap
    end

    it "scraps all categories" do
      @website1_scrapper.expects(:scrap_category).times(12)
      @website1_scrapper.do_scrap
    end
  end

  describe "initialize", vcr: true do
    context "API return websites" do
      it "sets website" do
        result = Website.new({"id" => "12345"})
        Website.stubs(:find_by).with(@url).returns([result])

        website = Website1Scrapper.new(@url)

        website.id.should == "12345"
      end
    end

    context "API return error" do
      it "sets website" do
        result = Website.new({"id" => "12345"})
        Website.stubs(:find_by).with(@url).returns(nil)

        expect {
          Website1Scrapper.new(@url)
          }.to raise_error(RuntimeError)
      end
    end
  end

  describe "home_page", vcr: true do
    it "navigates to home_page" do
      go_to_home_page
      @website1_scrapper.current_page.content.should match /Log-in/
    end
  end

  describe "sign_in", vcr: true do
    it "post sign in form" do
      go_to_home_page
      do_sign_in
      @website1_scrapper.current_page.content.should match /#{@user}/
    end
  end

  describe "top_page", vcr: true do
    it "navigates to top page" do
      go_to_top_page
      @website1_scrapper.current_page.content.should match /Top of/
    end
  end

  describe "category", vcr: true do
    it "sets current post" do
      go_to_category
      @website1_scrapper.current_post_name.should == "#{@category_name}_2014_February"
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
        @website1_scrapper.website = Website.new({"id" => "12345", "scrapping_date" => "01/02/2010", "url" => "www.foo.bar"})
        @website1_scrapper.current_post_name = "foobar_2010_January"
        @website1_scrapper.stubs(:parse_image).returns(nil)
        
        @website1_scrapper
      end

      it "creates a post" do
        page = go_to_category
        Post.expects(:create).with("12345", "foobar_2010_January").returns(Post.new({"id" => "6789"}))

        website1.scrap_category(page, month)
      end


      it "iterates on all links" do
        page = go_to_category
        Post.stubs(:create).returns(Post.new({"id" => "6789"}))
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
      link_reg_exp = YAML.load_file('private-conf/websites.yml')["website1"]["link_reg_exp"]
      current_page.links_with(:href => %r{#{link_reg_exp}}).second
    end

    it "do nothing if no image on link" do
      Image.stubs(:find_by).returns([Image.new({"key" => "image_key"})])
      ImageDownloader.any_instance.expects(:download).never
      @website1_scrapper.parse_image(link)
    end

    it "downloads found image" do
      image_url = YAML.load_file('spec/websites/websites_test_conf.yml')["website1"]["parse_image"]["first_image"]
      Image.stubs(:find_by).with('52ee82a14d6163a27e000000', {:source_url => image_url}).returns([])
      @website1_scrapper.current_page = current_page
      do_sign_in

      ImageDownloader.any_instance.expects(:download).once
      @website1_scrapper.parse_image(link)
    end

    context "Search API failure" do
      it "do nothing if no image on link" do
        Image.stubs(:find_by).returns(nil)
        ImageDownloader.any_instance.expects(:download).never
        @website1_scrapper.parse_image(link)
      end
    end
  end

  describe "download_image", vcr: true do
    let(:url) { "www.foo.bar/image.png" }

    before(:each) do
      @website1_scrapper.website = Website.new({"id" => "123", "scrapping_date" => "01/02/2010", "url" => "www.foo.bar"})
      @website1_scrapper.post_id = "456"
      Image.stubs(:find_by).returns([])
    end

    it "downloads image" do
      mock = ImageDownloader.new("key")
      mock.expects(:download).once
      ImageDownloader.any_instance.expects(:build_info).with("123", "456", url).returns(mock)

      @website1_scrapper.download_image(url)
    end

    context "invalid uri" do
      it "doesn't download image" do
        ImageDownloader.any_instance.stubs(:build_info).returns(stub(:key => nil))
        ImageDownloader.any_instance.expects(:download).never

        @website1_scrapper.download_image(url)
      end
    end
  end
end