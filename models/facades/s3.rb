require 'aws-sdk'

module Facades
  class S3
    attr_accessor :bucket
    
    def initialize
      AWS.config({
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
      })

      s3 = AWS::S3.new 
      @bucket = s3.buckets[ENV["S3_BUCKET"]]
    end

    def write(key, path_to_file)
      unless ENV['TEST']
        obj = @bucket.objects[key]
        obj.write(Pathname.new(path_to_file))
      end
    end

    def read(key, path_to_file)
      unless ENV['TEST']
        obj = @bucket.objects[key]
        File.open(path_to_file, 'wb') do |file|
          obj.read do |chunk|
            file.write(chunk)
          end
        end
      end
    end
  end
end