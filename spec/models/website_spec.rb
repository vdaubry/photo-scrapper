require 'spec_helper'
require_relative '../../models/website'

describe "Website" do

  describe "find_by" do
    let(:website_json) {'{"websites":[{"id":"506144650ed4c08d84000001","name":"some name","url":"some url","scrapping_date":"2010-01-01","images_to_sort_count":0,"latest_post_id":null}]}'}

    it "returns a website" do
      stub_request(:get, "http://localhost:3002/websites/search.json?url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => website_json, 
                  :status => 200)

      website = Website.find_by("www.foo.bar").first
      website.scrapping_date.should == Date.parse("2010-01-01")
      website.id.should == "506144650ed4c08d84000001"
      website.url.should == "some url"
    end

    it "retries 3 times" do
      Website.expects(:get).times(3).raises(Errno::ECONNRESET)

      Website.find_by("www.foo.bar")
    end
  end

  context "downlader api failure" do
    it "returns nil" do
      stub_request(:get, "http://localhost:3002/websites/search.json?url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'text/plain'},
                  :body => File.read("spec/ressources/api_website_search_failure.response"), 
                  :status => 500)
      
      website = Website.find_by("www.foo.bar")
      website.should == nil
    end
  end
end