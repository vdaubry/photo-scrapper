require 'spec_helper'
require_relative '../../models/post_api'

describe "PostApi" do

  let(:post_json) {'{"post":{"id":"5314e4264d6163063f020000","name":"some_name","status":"SORTED_STATUS","pages_url":["www.foo.bar","www.foo.bar1"]}}'}
  let(:posts_json) {'{"posts":[{"id":"5314e4264d6163063f020000","name":"some_name","status":"SORTED_STATUS","pages_url":["www.foo.bar","www.foo.bar1"]}]}'}

  describe "create" do
    it "returns a post" do
      stub_request(:post, "http://localhost:3002/websites/123/posts.json")
      .with(:body => {:post => {:name => "some_name"}})
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => post_json, 
                  :status => 200)

      post = PostApi.new.create(123, "some_name")
      post.name.should == "some_name"
      post.id.should == "5314e4264d6163063f020000"
    end

    it "retries 3 times" do
      PostApi.expects(:post).times(3).raises(Errno::ECONNRESET)

      PostApi.new.create(123, "some_name")
    end
  end

  describe "search" do
    it "returns matching posts" do
      stub_request(:get, "http://localhost:3002/websites/123/posts/search.json?post%5Bpage_url%5D=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => posts_json, 
                  :status => 200)

      post = PostApi.new.search(123, "www.foo.bar").first
      post.name.should == "some_name"
      post.id.should == "5314e4264d6163063f020000"
    end

    it "retries 3 times" do
      PostApi.expects(:get).times(3).raises(Errno::ECONNRESET)

      PostApi.new.search(123, "www.foo.bar")
    end
  end

  describe "update" do
    it "returns a post" do
      stub_request(:put, "http://localhost:3002/websites/123/posts/5314e4264d6163063f020000.json")
      .with(:body => {:post => {:page_url => "www.foo.bar"}})
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => post_json, 
                  :status => 200)

      post = PostApi.new.update(123, "5314e4264d6163063f020000", "www.foo.bar")
      post.name.should == "some_name"
      post.id.should == "5314e4264d6163063f020000"
    end

    it "retries 3 times" do
      PostApi.expects(:put).times(3).raises(Errno::ECONNRESET)

      PostApi.new.update(123, "5314e4264d6163063f020000", "www.foo.bar")
    end
  end

  describe "destroy" do
    it "calls delete" do
      stub_request(:delete, "http://localhost:3002/websites/123/posts/456.json")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => nil, 
                  :status => 200)

      PostApi.new.destroy(123, 456).should_not == nil
    end

    it "retries 3 times" do
      PostApi.expects(:delete).times(3).raises(Errno::ECONNRESET)

      PostApi.new.destroy(123, 456)
    end
  end
end