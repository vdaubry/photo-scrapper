require "spec_helper"
require_relative "../../../models/facades/sqs"

describe "Facades::SQS" do
  before(:each) do
    @mock_queue = mock('AWS::SQS::Queue')
    @mock_queue.stubs(:url).returns("AWS::SQS::Queue:https://sqs.us-east-1.amazonaws.com/fake/fake")
    AWS::SQS.any_instance.stub_chain(:queues, :named).returns(@mock_queue)
  end

  describe "new" do
    context "no queue exist" do
      it "creates image_download queue" do
        mock_queue_collection = mock('AWS::SQS::QueueCollection')
        mock_queue_collection.stubs(:named).raises(AWS::SQS::Errors::NonExistentQueue)
        mock_queue_collection.stubs(:create).returns(@mock_queue)
        AWS::SQS.any_instance.stubs(:queues).returns(mock_queue_collection)
        
        facade = Facades::SQS.new(ENV["WEBSITE_QUEUE_NAME"])

        facade.queue.url.should == "AWS::SQS::Queue:https://sqs.us-east-1.amazonaws.com/fake/fake"
      end
    end

    context "queue already exist" do
      it "gets image_download queue" do
        AWS::SQS.any_instance.stub_chain(:queues, :named).returns(@mock_queue)

        facade = Facades::SQS.new(ENV["WEBSITE_QUEUE_NAME"])
        
        facade.queue.url.should == "AWS::SQS::Queue:https://sqs.us-east-1.amazonaws.com/fake/fake"
      end
    end
  end

  describe "send" do
    context "not nil message" do
      it "adds message to queue" do
        @mock_queue.expects(:send_message).with("www.foo.bar/img.png")
        facade = Facades::SQS.new(ENV["WEBSITE_QUEUE_NAME"])
        facade.send("www.foo.bar/img.png")
      end
    end

    context "nil message" do
      it "doesn't adds message to queue" do
        @mock_queue.expects(:send_message).never
        facade = Facades::SQS.new(ENV["WEBSITE_QUEUE_NAME"])
        facade.send(nil)
      end
    end
  end
end