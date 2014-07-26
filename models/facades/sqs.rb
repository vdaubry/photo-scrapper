require 'aws-sdk'
require 'dotenv'

module Facades
  class SQS

    attr_accessor :queue

    def initialize
      Dotenv.load
      AWS.config({
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"],
      :region => "eu-west-1"
      })

      sqs = AWS::SQS.new 

      @queue = begin
                sqs.queues.named(ENV["QUEUE_NAME"])
              rescue AWS::SQS::Errors::NonExistentQueue => e
                sqs.queues.create(ENV["QUEUE_NAME"],
                  :visibility_timeout => 90,
                  :message_retention_period => 1209600)
              end
    end

    def send(message)
      puts "send message #{message} to queue #{@queue.url}"
      @queue.send_message("#{message}") unless message.nil?
    end
  end
end