require "spec_helper"

describe CanCan::AccessDenied do
  describe "with action and subject" do
    before(:each) do
      @exception = CanCan::AccessDenied.new(nil, :some_action, :some_subject)
    end

    it "has action and subject accessors" do
      expect(@exception.action).to eq(:some_action)
      expect(@exception.subject).to eq(:some_subject)
    end

    it "has a changable default message" do
      expect(@exception.message).to eq("You are not authorized to access this page.")
      @exception.default_message = "Unauthorized!"
      expect(@exception.message).to eq("Unauthorized!")
    end
  end

  describe "with only a message" do
    before(:each) do
      @exception = CanCan::AccessDenied.new("Access denied!")
    end

    it "has nil action and subject" do
      expect(@exception.action).to be_nil
      expect(@exception.subject).to be_nil
    end

    it "has passed message" do
      expect(@exception.message).to eq("Access denied!")
    end
  end

  describe "i18n in the default message" do
    after(:each) do
      I18n.backend = nil
    end

    it "uses i18n for the default message" do
      I18n.backend.store_translations :en, :unauthorized => {:default => "This is a different message"}
      @exception = CanCan::AccessDenied.new
      expect(@exception.message).to eq("This is a different message")
    end

    it "defaults to a nice message" do
      @exception = CanCan::AccessDenied.new
      expect(@exception.message).to eq("You are not authorized to access this page.")
    end

    it "does not use translation if a message is given" do
      @exception = CanCan::AccessDenied.new("Hey! You're not welcome here")
      expect(@exception.message).to eq("Hey! You're not welcome here")
      expect(@exception.message).to_not eq("You are not authorized to access this page.")
    end
  end
end
