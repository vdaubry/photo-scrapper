require 'spec_helper'
require_relative '../../websites/download'

class Fake
  include Download
end

describe "Download" do
  describe "send_image_message" do
    it "sends a SQS message" do
      DateTime.stubs(:now).returns(DateTime.parse("20/10/2010"))
      fake = Fake.new
      fake.expects(:send_except_for_test).with({website_id: 123, post_id: 456, image_url: "http://www.foo.bar", scrapped_at: '2010-10-20T00:00:00+00:00'}.to_json)
      fake.send_image_message(123, 456, "http://www.foo.bar")
    end
  end
end