require File.dirname(__FILE__) + '/../spec_helper'

class Ability
  include CanCan::Ability
  can :read, :all
  can :read, Symbol do |sym|
    sym
  end
  can :preview, :all do |object_class, object|
    [object_class, object]
  end
  can :manage, Array do |action, object|
    [action, object]
  end
end

class AdminAbility
  include CanCan::Ability
  can :manage, :all do |action, object_class, object|
    [action, object_class, object]
  end
end

describe Ability do
  before(:each) do
    @ability = Ability.new
  end
  
  it "should be able to :read anything" do
    @ability.can?(:read, String).should be_true
    @ability.can?(:read, 123).should be_true
  end
  
  it "should not have permission to do something it doesn't know about" do
    @ability.can?(:foodfight, String).should be_false
  end
  
  it "should return what block returns on a can call" do
    @ability.can?(:read, Symbol).should be_nil
    @ability.can?(:read, :some_symbol).should == :some_symbol
  end
  
  it "should pass class with object if :all objects are accepted" do
    @ability.can?(:preview, 123).should == [Fixnum, 123]
  end
  
  it "should pass class with no object if :all objects are accepted and class is passed directly" do
    @ability.can?(:preview, Hash).should == [Hash, nil]
  end
  
  it "should pass action and object for global manage actions" do
    @ability.can?(:stuff, [1, 2]).should == [:stuff, [1, 2]]
    @ability.can?(:stuff, Array).should == [:stuff, nil]
  end
end

describe AdminAbility do
  it "should return block result for action, object_class, and object for any action" do
    @ability = AdminAbility.new
    @ability.can?(:foo, 123).should == [:foo, Fixnum, 123]
    @ability.can?(:bar, Fixnum).should == [:bar, Fixnum, nil]
  end
end
