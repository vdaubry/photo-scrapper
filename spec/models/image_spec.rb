require 'spec_helper'
require_relative '../../models/image'

describe "Image" do
  
  describe "find_by" do
    let(:images_json) {'{"images":[{"id":"506144650ed4c08d84000001","key":"some_key","width":200,"height":300,"source_url":"www.foo.bar"}]}'}

    it "returns an image" do
      stub_request(:get, "http://localhost:3002/websites/123/images/search.json")
      .with(:body => "source_url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => images_json, 
                  :status => 200)
      
      images = Image.find_by("123", {:source_url => "www.foo.bar"})
      images.first.key.should == "some_key"
    end

    it "returns empty images" do
      stub_request(:get, "http://localhost:3002/websites/123/images/search.json")
      .with(:body => "source_url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => '{"images":[]}', 
                  :status => 200)
      
      images = Image.find_by("123", {:source_url => "www.foo.bar"})
      images.first.should == nil
    end

    it "retries 3 times" do
      Image.expects(:get).times(3).raises(Errno::ECONNRESET)

      Image.find_by("123", {:source_url => "www.foo.bar"})
    end

    context "downlader api failure" do
      it "returns nil" do
        stub_request(:get, "http://localhost:3002/websites/123/images/search.json")
        .with(:body => "source_url=www.foo.bar")
        .to_return(:headers => {"Content-Type" => 'text/plain'},
                    :body => File.read("spec/ressources/api_image_search_failure.response"), 
                    :status => 500)
        
        images = Image.find_by("123", {:source_url => "www.foo.bar"})
        images.should == nil
      end
    end
  end

  describe "create" do    
    let(:image_json) {'{"image":{"id":"506144650ed4c08d84000001","key":"some_key","width":200,"height":300,"source_url":"www.foo.bar"}}'}

    it "returns an image" do
      stub_request(:post, "http://localhost:3002/websites/123/posts/456/images.json").
        with(:body => "image[source_url]=www.foo.bar%2Fimage.png&image[hosting_url]=www.foo.bar&image[key]=543_image.png&image[status]=TO_SORT_STATUS&image[image_hash]=dfg2345679876&image[width]=400&image[height]=400&image[file_size]=123456").
        to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => image_json, 
                  :status => 200)
      
      image = Image.create("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456)
      image.key.should == "some_key"
    end

    it "returns nil" do
      stub_request(:post, "http://localhost:3002/websites/123/posts/456/images.json").
        with(:body => "image[source_url]=www.foo.bar%2Fimage.png&image[hosting_url]=www.foo.bar&image[key]=543_image.png&image[status]=TO_SORT_STATUS&image[image_hash]=dfg2345679876&image[width]=400&image[height]=400&image[file_size]=123456").
        to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => nil, 
                  :status => 200)
      
      image = Image.create("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456)
      image.should == nil
    end

    it "returns 404" do
      stub_request(:post, "http://localhost:3002/websites/123/posts/456/images.json").
        with(:body => "image[source_url]=www.foo.bar%2Fimage.png&image[hosting_url]=www.foo.bar&image[key]=543_image.png&image[status]=TO_SORT_STATUS&image[image_hash]=dfg2345679876&image[width]=400&image[height]=400&image[file_size]=123456").
        to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => "not found", 
                  :status => 404)
      
      image = Image.create("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456)
      image.should == nil
    end

    it "returns nil if errors" do
      stub_request(:post, "http://localhost:3002/websites/123/posts/456/images.json").
        with(:body => "image[source_url]=www.foo.bar%2Fimage.png&image[hosting_url]=www.foo.bar&image[key]=543_image.png&image[status]=TO_SORT_STATUS&image[image_hash]=dfg2345679876&image[width]=200&image[height]=200&image[file_size]=123456").
        to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => '{"errors":["Width too small"]}', 
                  :status => 422)
      
      image = Image.create("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 200, 200, 123456)
      image.should == nil
    end

    it "retries 3 times" do
      Image.expects(:post).times(3).raises(Errno::ECONNRESET)

      Image.create("123", "456", "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456)
    end
  end
end