require 'spec_helper'
require_relative '../../models/image_api'

describe "ImageApi" do
  
  describe "search" do
    let(:images_json) {'{"images":[{"id":"506144650ed4c08d84000001","key":"some_key","width":200,"height":300,"source_url":"www.foo.bar"}]}'}

    it "returns an image" do
      stub_request(:get, "http://localhost:3002/websites/123/images/search.json?source_url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => images_json, 
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

  describe "post" do    
    let(:image_json) {'{"image":{"id":"506144650ed4c08d84000001","key":"some_key","width":200,"height":300,"source_url":"www.foo.bar"}}'}

    it "returns an image" do
      stub_request(:post, "http://localhost:3002/websites/123/posts/456/images.json").
        with(:body => "source_url=www.foo.bar%2Fimage.png&hosting_url=www.foo.bar&key=543_image.png&status=TO_SORT_STATUS&image_hash=dfg2345679876&width=400&height=400&file_size=123456").
        to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => image_json, 
                  :status => 200)
      
      image = ImageApi.new.post("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456)
      image.key.should == "some_key"
    end

    it "returns nil" do
      stub_request(:post, "http://localhost:3002/websites/123/posts/456/images.json").
        with(:body => "source_url=www.foo.bar%2Fimage.png&hosting_url=www.foo.bar&key=543_image.png&status=TO_SORT_STATUS&image_hash=dfg2345679876&width=400&height=400&file_size=123456").
        to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => nil, 
                  :status => 200)
      
      image = ImageApi.new.post("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456)
      image.should == nil
    end
  end
end