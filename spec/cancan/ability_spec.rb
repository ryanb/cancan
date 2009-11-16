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
end

describe CanCan::Ability do
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
end
