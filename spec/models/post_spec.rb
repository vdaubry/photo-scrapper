require 'spec_helper'
require_relative '../../models/post'

describe "Post" do

  let(:post_json) {'{"post":{"id":"5314e4264d6163063f020000","name":"some_name","status":"SORTED_STATUS","pages_url":["www.foo.bar","www.foo.bar1"],"banished":true}}'}
  let(:posts_json) {'{"posts":[{"id":"5314e4264d6163063f020000","name":"some_name","status":"SORTED_STATUS","pages_url":["www.foo.bar","www.foo.bar1"],"banished":false}]}'}

  describe "create" do
    it "returns a post" do
      stub_request(:post, "http://localhost:3002/websites/123/posts.json")
      .with(:body => {:post => {:name => "some_name"}})
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => post_json, 
                  :status => 200)

      post = Post.create(123, "some_name")
      post.name.should == "some_name"
      post.id.should == "5314e4264d6163063f020000"
      post.banished.should == true
    end

    it "retries 3 times" do
      Post.expects(:post).times(3).raises(Errno::ECONNRESET)

      Post.create(123, "some_name")
    end
  end

  describe "find_by" do
    it "returns matching posts" do
      stub_request(:get, "http://localhost:3002/websites/123/posts/search.json?page_url=www.foo.bar")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => posts_json, 
                  :status => 200)

      post = Post.find_by(123, "www.foo.bar").first
      post.name.should == "some_name"
      post.id.should == "5314e4264d6163063f020000"
    end

    it "retries 3 times" do
      Post.expects(:get).times(3).raises(Errno::ECONNRESET)

      Post.find_by(123, "www.foo.bar")
    end
  end

  describe "update" do
    it "returns a post" do
      stub_request(:put, "http://localhost:3002/websites/123/posts/5314e4264d6163063f020000.json")
      .with(:body => {:post => {:page_url => "www.foo.bar"}})
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => post_json, 
                  :status => 200)

      post = Post.update(123, "5314e4264d6163063f020000", "www.foo.bar")
      post.name.should == "some_name"
      post.id.should == "5314e4264d6163063f020000"
    end

    it "retries 3 times" do
      Post.expects(:put).times(3).raises(Errno::ECONNRESET)

      Post.update(123, "5314e4264d6163063f020000", "www.foo.bar")
    end
  end

  describe "destroy" do
    it "calls delete" do
      stub_request(:delete, "http://localhost:3002/websites/123/posts/456.json")
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => nil, 
                  :status => 200)

      Post.destroy(123, 456).should_not == nil
    end

    it "retries 3 times" do
      Post.expects(:delete).times(3).raises(Errno::ECONNRESET)

      Post.destroy(123, 456)
    end
  end
end