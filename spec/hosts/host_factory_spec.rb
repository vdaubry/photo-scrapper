require 'spec_helper'
require_relative '../../hosts/host_factory'

describe "HostFactory", :local => :true do

  describe "create_with_host_url" do

    context "known host" do
      it "creates host" do
        url = YAML.load_file("spec/hosts/hosts_conf_spec.yml")["create_with_host_url"]["host_url"]
        HostFactory.create_with_host_url(url).should be_a(Host1)
      end
    end

    context "unknown host" do
      it "creates generic host" do
        HostFactory.create_with_host_url("http://www.foo.bar").should be_a(GenericHost)
      end
    end

    context "invalid url" do
      it "returns nil" do
        HostFactory.create_with_host_url("www.foo").should == nil
      end
    end    
  end

end