require "spec_helper"

describe CanCan::AccessDenied do
  describe "with action and subject" do
    before(:each) do
      @exception = CanCan::AccessDenied.new(nil, :some_action, :some_subject)
    end

    it "should have action and subject accessors" do
      @exception.action.should == :some_action
      @exception.subject.should == :some_subject
    end

    it "should have a changable default message" do
      @exception.message.should == "You are not authorized to access this page."
      @exception.default_message = "Unauthorized!"
      @exception.message.should == "Unauthorized!"
    end
  end

  describe "with only a message" do
    before(:each) do
      @exception = CanCan::AccessDenied.new("Access denied!")
    end

    it "should have nil action and subject" do
      @exception.action.should be_nil
      @exception.subject.should be_nil
    end

    it "should have passed message" do
      @exception.message.should == "Access denied!"
    end
  end
end
