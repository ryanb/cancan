require File.dirname(__FILE__) + '/../spec_helper'

describe CanCan::ControllerAdditions do
  before(:each) do
    @controller_class = Class.new
    @controller = @controller_class.new
    stub(@controller).params { {} }
    mock(@controller_class).helper_method(:can?, :cannot?)
    @controller_class.send(:include, CanCan::ControllerAdditions)
  end
  
  it "should raise access denied with default message when calling unauthorized!" do
    lambda {
      @controller.unauthorized!
    }.should raise_error(CanCan::AccessDenied, "You are not authorized to access this page.")
  end
  
  it "should raise access denied with custom message when calling unauthorized!" do
    lambda {
      @controller.unauthorized! "Access denied!"
    }.should raise_error(CanCan::AccessDenied, "Access denied!")
  end
  
  it "should have a current_ability method which generates an ability for the current user" do
    stub(@controller).current_user { :current_user }
    @controller.current_ability.should be_kind_of(Ability)
  end
  
  it "should provide a can? and cannot? methods which go through the current ability" do
    stub(@controller).current_user { :current_user }
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
    @controller.cannot?(:foo, :bar).should be_true
  end
  
  it "load_and_authorize_resource should setup a before filter which passes call to ResourceAuthorization" do
    stub(CanCan::ResourceAuthorization).new(@controller, @controller.params, :foo => :bar).mock!.load_and_authorize_resource
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    @controller_class.load_and_authorize_resource :foo => :bar
  end
  
  it "authorize_resource should setup a before filter which passes call to ResourceAuthorization" do
    stub(CanCan::ResourceAuthorization).new(@controller, @controller.params, :foo => :bar).mock!.authorize_resource
    mock(@controller_class).before_filter(:except => :show) { |options, block| block.call(@controller) }
    @controller_class.authorize_resource :foo => :bar, :except => :show
  end
  
  it "load_resource should setup a before filter which passes call to ResourceAuthorization" do
    stub(CanCan::ResourceAuthorization).new(@controller, @controller.params, :foo => :bar).mock!.load_resource
    mock(@controller_class).before_filter(:only => [:show, :index]) { |options, block| block.call(@controller) }
    @controller_class.load_resource :foo => :bar, :only => [:show, :index]
  end
end
