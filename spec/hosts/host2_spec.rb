require 'spec_helper'
require_relative '../../hosts/host2'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "Host2", :local => true do
  let(:url) { YAML.load_file("spec/hosts/hosts_conf_spec.yml")["host2"]["page_url"] }

  describe "all_images", :vcr => true do

    it "returns image" do
      expect_image = YAML.load_file("spec/hosts/hosts_conf_spec.yml")["host2"]["image_url"]

      Host2.new(url).all_images.first.url.to_s.should == expect_image
    end

  end
end