require 'spec_helper'

require_relative '../../scrappers/scrapper_factory'
require_relative '../../websites/forum1_scrapper'
require_relative '../../websites/website2_scrapper'
require_relative '../../websites/tumblr/tumblr3_scrapper'


describe "scrapper" do
  before(:each) do
    Website.stubs(:find_by).returns([])
  end
  
  it "finds Forum1 scrapper based on name" do
    ScrapperFactory.new("forum1").scrapper.should be_a Forum1Scrapper
  end

  it "finds Website2 scrapper based on name" do
    ScrapperFactory.new("website2").scrapper.should be_a Website2Scrapper
  end

  it "finds Tumblr3 scrapper based on name" do
    ScrapperFactory.new("tumblr3").scrapper.should be_a Tumblr3Scrapper
  end

  context "website name doesn't exist" do
    it "raises exception" do
      expect { ScrapperFactory.new("foo").scrapper }.to raise_error
    end
  end

  context "no class corresponds to website name" do
    it "raises exception" do
      Object.stubs(:const_get).raises(Exception)
      expect { ScrapperFactory.new("forum1").scrapper }.to raise_error
    end
  end
end

