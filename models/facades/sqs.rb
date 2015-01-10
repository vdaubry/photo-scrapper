require 'aws-sdk'
require 'dotenv'

module Facades
  class SQS

    attr_accessor :queue

    def initialize(queue_name)
      Dotenv.load
      AWS.config({
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"],
      :region => "eu-west-1"
      })

      sqs = AWS::SQS.new 
      @queue_name = queue_name
      @queue = begin
                sqs.queues.named(queue_name)
              rescue AWS::SQS::Errors::NonExistentQueue => e
                sqs.queues.create(queue_name,
                  :visibility_timeout => 43200,
                  :message_retention_period => 1209600)
              end
    end

    def send(message)
      puts "send message #{message} to queue #{@queue.url}"
      Thread.new do
        AWS::SQS.new.queues.named(@queue_name).send_message("#{message}") unless message.nil?
      end
    end

    def poll
      puts "Start polling queue : #{@queue.url}"
      @queue.poll do |received_message| 
        yield(received_message.body)
        received_message.delete
      end
    end
  end
end