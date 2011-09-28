require "spec_helper"
require "cancan/matchers"

describe Ability do
  describe "as guest" do
    before(:each) do
      @ability = Ability.new(nil)
    end

    it "can only create a user" do
      # Define what a guest can and cannot do
      # @ability.should be_able_to(:create, :users)
      # @ability.should_not be_able_to(:update, :users)
    end
  end
end
