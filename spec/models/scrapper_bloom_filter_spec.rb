require "spec_helper"
require "benchmark"
require_relative "../../models/scrapper_bloom_filter"


describe "ScrapperBoomFilter" do

  let(:filter_path) {"spec/ressources/bloom.dump"}
  describe "new" do
    before(:each) do
      File.delete(filter_path) if File.exists?(filter_path)
    end
    context "no previous saved filter" do
      it "creates a new filter" do
        ScrapperBloomFilter.new(filter_path)
        File.exists?(filter_path).should == true
      end
    end
    
    context "has a previous saved filter" do
      it "loads the filter" do
        bf = ScrapperBloomFilter.new(filter_path)
        bf.insert("foo")
        bf.save
        bf2 = ScrapperBloomFilter.new(filter_path)
        bf2.include?("foo").should == true
      end
    end
  end
  
  describe "insert / include" do
    before(:each) do
      File.delete(filter_path) if File.exists?(filter_path)
    end
    
    it "adds a new element to filter" do
      bf = ScrapperBloomFilter.new(filter_path)
      bf.insert("foo")
      bf.include?("foo").should == true
      bf.include?("foo1").should == false
    end
    
    it "doesn't inserts nil" do
      bf = ScrapperBloomFilter.new(filter_path)
      bf.insert(nil) rescue InvalidKeyError
      bf.include?(nil).should == false
    end
    
    it "doesn't inserts empty" do
      bf = ScrapperBloomFilter.new(filter_path)
      bf.insert("") rescue InvalidKeyError
      bf.include?("").should == false
    end
    
    # Benchmarks
    # it "adds lots of elements" do
    #   bf = ScrapperBloomFilter.new(filter_path)
      
    #   1000000.times do |i|
    #     bf.insert("foo#{i}")
    #   end
      
    #   10.times do
    #     puts Benchmark.measure {
    #       bf.insert("foo#{rand(10000)}")
    #     }
    #   end
      
    # end
  end
end