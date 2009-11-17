require File.dirname(__FILE__) + '/../spec_helper'

class Ability
  include CanCan::Ability
end

describe CanCan::ControllerAdditions do
  before(:each) do
    @controller_class = Class.new
    @controller = @controller_class.new
    mock(@controller_class).helper_method(:can?)
    @controller_class.send(:include, CanCan::ControllerAdditions)
  end
  
  it "should read from the cache with request uri as key and render that text" do
    lambda {
      @controller.unauthorized!
    }.should raise_error(CanCan::AccessDenied)
  end
  
  it "should have a current_ability method which generates an ability for the current user" do
    stub(@controller).current_user { :current_user }
    @controller.current_ability.should be_kind_of(Ability)
    @controller.current_ability.user.should == :current_user
  end
  
  it "should provide a can? method which goes through the current ability" do
    stub(@controller).current_user { :current_user }
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
  end
end
