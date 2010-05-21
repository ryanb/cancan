require "spec_helper"

describe CanCan::Ability do
  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should be able to :read anything" do
    @ability.can :read, :all
    @ability.can?(:read, String).should be_true
    @ability.can?(:read, 123).should be_true
  end

  it "should not have permission to do something it doesn't know about" do
    @ability.can?(:foodfight, String).should be_false
  end

  it "should return what block returns on a can call" do
    @ability.can :read, :all
    @ability.can :read, Symbol do |sym|
      sym
    end
    @ability.can?(:read, Symbol).should be_nil
    @ability.can?(:read, :some_symbol).should == :some_symbol
  end

  it "should pass class with object if :all objects are accepted" do
    @ability.can :preview, :all do |object_class, object|
      [object_class, object]
    end
    @ability.can?(:preview, 123).should == [Fixnum, 123]
  end

  it "should pass class with no object if :all objects are accepted and class is passed directly" do
    @ability.can :preview, :all do |object_class, object|
      [object_class, object]
    end
    @ability.can?(:preview, Hash).should == [Hash, nil]
  end

  it "should pass action and object for global manage actions" do
    @ability.can :manage, Array do |action, object|
      [action, object]
    end
    @ability.can?(:stuff, [1, 2]).should == [:stuff, [1, 2]]
    @ability.can?(:stuff, Array).should == [:stuff, nil]
  end

  it "should alias update or destroy actions to modify action" do
    @ability.alias_action :update, :destroy, :to => :modify
    @ability.can(:modify, :all) { :modify_called }
    @ability.can?(:update, 123).should == :modify_called
    @ability.can?(:destroy, 123).should == :modify_called
  end

  it "should return block result for action, object_class, and object for any action" do
    @ability.can :manage, :all do |action, object_class, object|
      [action, object_class, object]
    end
    @ability.can?(:foo, 123).should == [:foo, Fixnum, 123]
    @ability.can?(:bar, Fixnum).should == [:bar, Fixnum, nil]
  end

  it "should automatically alias index and show into read calls" do
    @ability.can :read, :all
    @ability.can?(:index, 123).should be_true
    @ability.can?(:show, 123).should be_true
  end

  it "should automatically alias new and edit into create and update respectively" do
    @ability.can(:create, :all) { :create_called }
    @ability.can(:update, :all) { :update_called }
    @ability.can?(:new, 123).should == :create_called
    @ability.can?(:edit, 123).should == :update_called
  end

  it "should not respond to prepare (now using initialize)" do
    @ability.should_not respond_to(:prepare)
  end

  it "should offer cannot? method which is simply invert of can?" do
    @ability.cannot?(:tie, String).should be_true
  end

  it "should be able to specify multiple actions and match any" do
    @ability.can [:read, :update], :all
    @ability.can?(:read, 123).should be_true
    @ability.can?(:update, 123).should be_true
    @ability.can?(:count, 123).should be_false
  end

  it "should be able to specify multiple classes and match any" do
    @ability.can :update, [String, Array]
    @ability.can?(:update, "foo").should be_true
    @ability.can?(:update, []).should be_true
    @ability.can?(:update, 123).should be_false
  end

  it "should support custom objects in the can definition" do
    @ability.can :read, :stats
    @ability.can?(:read, :stats).should be_true
    @ability.can?(:update, :stats).should be_false
    @ability.can?(:read, :nonstats).should be_false
  end

  it "should support 'cannot' method to define what user cannot do" do
    @ability.can :read, :all
    @ability.cannot :read, Integer
    @ability.can?(:read, "foo").should be_true
    @ability.can?(:read, 123).should be_false
  end

  it "should support block on 'cannot' method" do
    @ability.can :read, :all
    @ability.cannot :read, Integer do |int|
      int > 5
    end
    @ability.can?(:read, "foo").should be_true
    @ability.can?(:read, 3).should be_true
    @ability.can?(:read, 123).should be_false
  end

  it "should append aliased actions" do
    @ability.alias_action :update, :to => :modify
    @ability.alias_action :destroy, :to => :modify
    @ability.aliased_actions[:modify].should == [:update, :destroy]
  end

  it "should clear aliased actions" do
    @ability.alias_action :update, :to => :modify
    @ability.clear_aliased_actions
    @ability.aliased_actions[:modify].should be_nil
  end

  it "should pass additional arguments to block from can?" do
    @ability.can :read, Integer do |int, x|
      int > x
    end
    @ability.can?(:read, 2, 1).should be_true
    @ability.can?(:read, 2, 3).should be_false
  end

  it "should use conditions as third parameter and determine abilities from it" do
    @ability.can :read, Array, :first => 1, :last => 3
    @ability.can?(:read, [1, 2, 3]).should be_true
    @ability.can?(:read, [1, 2, 3, 4]).should be_false
    @ability.can?(:read, Array).should be_true
  end

  it "should allow an array of options in conditions hash" do
    @ability.can :read, Array, :first => [1, 3, 5]
    @ability.can?(:read, [1, 2, 3]).should be_true
    @ability.can?(:read, [2, 3]).should be_false
    @ability.can?(:read, [3, 4]).should be_true
  end

  it "should allow a range of options in conditions hash" do
    @ability.can :read, Array, :first => 1..3
    @ability.can?(:read, [1, 2, 3]).should be_true
    @ability.can?(:read, [3, 4]).should be_true
    @ability.can?(:read, [4, 5]).should be_false
  end

  it "should allow nested hashes in conditions hash" do
    @ability.can :read, Array, :first => { :length => 5 }
    @ability.can?(:read, ["foo", "bar"]).should be_false
    @ability.can?(:read, ["test1", "foo"]).should be_true
  end

  it "should allow nested hash of arrays and match any element" do
    @ability.can :read, Array, :first => { :to_i => 3 }
    @ability.can?(:read, [[1, 2, 3]]).should be_true
    @ability.can?(:read, [[4, 5, 6]]).should be_false
  end

  it "should return conditions for a given ability" do
    @ability.can :read, Array, :first => 1, :last => 3
    @ability.conditions(:show, Array).should == {:first => 1, :last => 3}
  end

  it "should raise an exception when a block is used on condition" do
    @ability.can :read, Array do |a|
      true
    end
    lambda { @ability.conditions(:show, Array) }.should raise_error(CanCan::Error, "Cannot determine ability conditions from block for :show Array")
  end

  it "should return an empty hash for conditions when there are no conditions" do
    @ability.can :read, Array
    @ability.conditions(:show, Array).should == {}
  end

  it "should return false when performed on an action which isn't defined" do
    @ability.conditions(:foo, Array).should == false
  end

  it "should has eated cheezburger" do
    lambda {
      @ability.can? :has, :cheezburger
    }.should raise_exception(CanCan::Error, "Nom nom nom. I eated it.")
  end
end
