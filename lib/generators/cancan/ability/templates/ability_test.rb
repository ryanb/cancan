require "test_helper"

class AbilityTest < ActiveSupport::TestCase
  def guest_can_only_create_user
    ability = Ability.new(nil)
    # Define what a guest can and cannot do
    # assert ability.can?(:create, :users)
    # assert ability.cannot?(:update, :users)
  end
end
