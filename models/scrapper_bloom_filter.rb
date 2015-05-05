require 'bloomfilter-rb'

class InvalidKeyError < StandardError; end

class ScrapperBloomFilter
  attr_accessor :bf
  
  def initialize(file_path)
    options = {
      :size => 45402336,        # size of bit vector (45Mo)
      :hashes => 13,            # number of hash functions => http://hur.st/bloomfilter?n=20000000&p=0.0001
      :seed => Time.now.to_i,   # seed value for the filter
      :bucket => 8,             # number of bits for the counting filter (1 = no counting filter)
      :raise => true            # raise on bucket overflow?
    }
    
    @file_path = file_path
    if File.exists?(@file_path)
      puts "loading saved filter #{@file_path}"
      @bf = BloomFilter::Native.load(@file_path)
    else
      puts "no saved filter, creating new filter at #{@file_path}"
      @bf = BloomFilter::Native.new(options)
      save
    end
  end
  
  def insert(str)
    raise InvalidKeyError, "tried to insert nil or empty value in bloom filter" if str.to_s.empty?
    @bf.insert(str)
  end
  
  def include?(str)
    @bf.include?(str)
  end
  
  def save
    @bf.save(@file_path)
  end
end