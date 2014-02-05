require "spec_helper"

describe CanCan::Unauthorized do
  describe "with action, subject, and attribute" do
    before(:each) do
      @exception = CanCan::Unauthorized.new(nil, :some_action, :some_subject, :some_attr)
    end

    it "has action, subject, and attribute accessors" do
      @exception.action.should == :some_action
      @exception.subject.should == :some_subject
      @exception.attribute.should == :some_attr
    end
  end

  describe "with action and subject" do
    before(:each) do
      @exception = CanCan::Unauthorized.new(nil, :some_action, :some_subject)
    end

    it "has action and subject accessors" do
      @exception.action.should == :some_action
      @exception.subject.should == :some_subject
      @exception.attribute.should be_nil
    end

    it "has a changable default message" do
      @exception.message.should == "You are not authorized to access this page."
      @exception.default_message = "Unauthorized!"
      @exception.message.should == "Unauthorized!"
    end
  end

  describe "with only a message" do
    before(:each) do
      @exception = CanCan::Unauthorized.new("Access denied!")
    end

    it "has nil action, subject, and attribute" do
      @exception.action.should be_nil
      @exception.subject.should be_nil
      @exception.attribute.should be_nil
    end

    it "has passed message" do
      @exception.message.should == "Access denied!"
    end
  end

  describe "i18n in the default message" do
    after(:each) do
      I18n.backend = nil
    end

    it "uses i18n for the default message" do
      I18n.backend.store_translations :en, :unauthorized => {:default => "This is a different message"}
      @exception = CanCan::Unauthorized.new
      @exception.message.should == "This is a different message"
    end

    it "defaults to a nice message" do
      @exception = CanCan::Unauthorized.new
      @exception.message.should == "You are not authorized to access this page."
    end

    it "does not use translation if a message is given" do
      @exception = CanCan::Unauthorized.new("Hey! You're not welcome here")
      @exception.message.should == "Hey! You're not welcome here"
      @exception.message.should_not == "You are not authorized to access this page."
    end
  end
end
