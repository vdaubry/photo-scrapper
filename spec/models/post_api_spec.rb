require 'spec_helper'
require_relative '../../models/post_api'

describe "PostApi" do

  describe "create" do
    let(:post_json) {'{"post":{"id":"5314e4264d6163063f020000","name":"some_name","status":"SORTED_STATUS","pages_url":["www.foo.bar","www.foo.bar1"]}}'}

    it "returns a post" do
      stub_request(:post, "http://localhost:3002/websites/123/posts.json")
      .with(:body => {:post => {:name => "some_name"}})
      .to_return(:headers => {"Content-Type" => 'application/json'},
                  :body => post_json, 
                  :status => 200)

      post = PostApi.new.create(123, "some_name")
      post.name.should == "some_name"
    end
  end
end