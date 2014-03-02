require 'spec_helper'
require_relative '../../models/website_api'

describe "WebsiteApi" do

  describe "search" do
    let(:website_json) {'{"websites":[{"id":"506144650ed4c08d84000001","name":"some name","url":"some url","last_scrapping_date":"2010-01-01","images_to_sort_count":0,"latest_post_id":null}]}'}

    it "returns a website" do
      stub_request(:get, "http://localhost:3002/websites/search.json?url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => website_json, 
                  :status => 200)

      websites = WebsiteApi.new.search("www.foo.bar")
      websites.first.last_scrapping_date.should == Date.parse("2010-01-01")
    end
  end
end