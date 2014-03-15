require 'spec_helper'
require_relative '../../models/scrapping_api'

describe "ScrappingApi" do

  let(:scrapping_json) {'{"scrapping":{"id":"5314e4264d6163063f020000","date":"2010-01-02T00:00:00.000Z","duration":3600,"image_count":123,"success":false}}'}

  describe "create" do
    it "returns a scrapping" do
      stub_request(:post, "http://localhost:3002/websites/123/scrappings.json")
      .with(:body => "scrapping[date]=2012-01-02")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => scrapping_json, 
                  :status => 200)

      scrapping = ScrappingApi.new.create(123, Date.parse("2012/01/02"))
      scrapping.date.should == "2010-01-02T00:00:00.000Z"
      scrapping.id.should == "5314e4264d6163063f020000"
    end
  end

  describe "update" do
    let(:valid_attributes) { { :date => "02/01/2010", :duration => 3600, :image_count => 123, :success => false } }
    it "returns a post" do
      stub_request(:put, "http://localhost:3002/websites/123/scrappings/5314e4264d6163063f020000.json")
      .with(:body => "scrapping[date]=02%2F01%2F2010&scrapping[duration]=3600&scrapping[image_count]=123&scrapping[success]=false")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => scrapping_json, 
                  :status => 200)

      post = ScrappingApi.new.update(123, "5314e4264d6163063f020000", valid_attributes)
      post.id.should == "5314e4264d6163063f020000"
    end
  end
end