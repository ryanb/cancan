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

  describe "i18n in the default message" do
    after(:each) do
      I18n.backend = nil
    end

    it "uses i18n for the default message" do
      I18n.backend.store_translations :en, :unauthorized => {:default => "This is a different message"}
      @exception = CanCan::AccessDenied.new
      @exception.message.should == "This is a different message"
    end

    it "defaults to a nice message" do
      @exception = CanCan::AccessDenied.new
      @exception.message.should == "You are not authorized to access this page."
    end

    it "does not use translation if a message is given" do
      @exception = CanCan::AccessDenied.new("Hey! You're not welcome here")
      @exception.message.should == "Hey! You're not welcome here"
      @exception.message.should_not == "You are not authorized to access this page."
    end
  end
end
