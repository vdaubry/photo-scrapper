require 'spec_helper'
require_relative '../../hosts/generic_host'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassette_library'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

describe "GenericHost", :local => true do
  let(:url) { YAML.load_file("spec/hosts/hosts_conf_spec.yml")["generic_host"]["parse_image"]["host_url"] }
  let(:generic_host) { GenericHost.new(url) }

  describe "image_url", :vcr => true do
    context "has main image" do
      it "returns only the main image" do
        expected_image = YAML.load_file("spec/hosts/hosts_conf_spec.yml")["generic_host"]["parse_image"]["image_url"]
        generic_host.image_url.should == expected_image
      end

      it "excludes icon images" do
        icon_url = YAML.load_file("spec/hosts/hosts_conf_spec.yml")["generic_host"]["parse_image"]["icon_url"]
        GenericHost.new(icon_url).image_url.should =~ /7936009/
      end
    end

    context "No main image" do
      it "returns nil" do
        GenericHost.new("http://www.google.fr").image_url.should == nil
      end
    end

    context "Net::HTTPNotFound" do
      it "returns nil" do
        unhandled_response_url = YAML.load_file("spec/hosts/hosts_conf_spec.yml")["generic_host"]["parse_image"]["unhandled_response_url"]
        GenericHost.new(unhandled_response_url).image_url.should == nil
      end
    end

    context "URI::InvalidURIError" do
      it "returns nil" do
        invalid_uri = YAML.load_file("spec/hosts/hosts_conf_spec.yml")["generic_host"]["parse_image"]["invalid_uri"]
        GenericHost.new(invalid_uri).image_url.should == nil
      end
    end

    context "SocketError" do
      it "returns nil" do
        Mechanize.any_instance.stubs(:get).raises(SocketError)
        GenericHost.new("http://www.google.fr").image_url.should == nil
      end
    end

    context "Zlib::BufError" do
      it "returns nil" do
        Mechanize.any_instance.stubs(:get).raises(Zlib::BufError)
        GenericHost.new("http://www.google.fr").image_url.should == nil
      end
    end
  end
end