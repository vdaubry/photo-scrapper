require 'aws-sdk'
require 'dotenv'

module Facades
  class SQS

    attr_accessor :queue

    def initialize
      Dotenv.load
      AWS.config({
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
      })

      sqs = AWS::SQS.new 

      @queue = begin
                sqs.queues.named("image_downloader")
              rescue AWS::SQS::Errors::NonExistentQueue => e
                sqs.queues.create("image_downloader")
              end
    end

    def send(message)
      @queue.send_message("#{message}") unless message.nil?
    end

    def poll
      @queue.poll do |received_message| 
        yield(received_message.body)
      end
    end
  end
end