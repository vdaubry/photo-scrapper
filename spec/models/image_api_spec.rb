require 'spec_helper'
require_relative '../../models/image_api'

describe "ImageApi" do
  describe "search" do
    let(:image_json) {'{"images":[{"id":"506144650ed4c08d84000001","key":"some_key","width":200,"height":300,"source_url":"www.foo.bar"}]}'}

    it "returns an image" do
      stub_request(:get, "http://localhost:3002/websites/123/images/search.json?source_url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => image_json, 
                  :status => 200)
      
      images = ImageApi.new.search("123", "www.foo.bar")
      images.first.key.should == "some_key"
    end

    it "returns empty images" do
      stub_request(:get, "http://localhost:3002/websites/123/images/search.json?source_url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => '{"images":[]}', 
                  :status => 200)
      
      images = ImageApi.new.search("123", "www.foo.bar")
      images.first.should == nil
    end
  end
end