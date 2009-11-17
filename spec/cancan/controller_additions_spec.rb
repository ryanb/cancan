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
  end
  
  it "should provide a can? method which goes through the current ability" do
    stub(@controller).current_user { :current_user }
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
  end
  
  it "should load the resource if params[:id] is specified" do
    stub(@controller).params { {:controller => "abilities", :action => "show", :id => 123} }
    stub(Ability).find(123) { :some_resource }
    @controller.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should build a new resource with hash if params[:id] is not specified" do
    stub(@controller).params { {:controller => "abilities", :action => "create", :ability => {:foo => "bar"}} }
    stub(Ability).new(:foo => "bar") { :some_resource }
    @controller.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should build a new resource even if attribute hash isn't specified" do
    stub(@controller).params { {:controller => "abilities", :action => "new"} }
    stub(Ability).new(nil) { :some_resource }
    @controller.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should not build a resource when on index action" do
    stub(@controller).params { {:controller => "abilities", :action => "index"} }
    @controller.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end
  
  it "should perform authorization using controller action and loaded model" do
    @controller.instance_variable_set(:@ability, :some_resource)
    stub(@controller).params { {:controller => "abilities", :action => "show"} }
    stub(@controller).can?(:show, :some_resource) { false }
    lambda {
      @controller.authorize_resource
    }.should raise_error(CanCan::AccessDenied)
  end
  
  it "should perform authorization using controller action and non loaded model" do
    stub(@controller).params { {:controller => "abilities", :action => "show"} }
    stub(@controller).can?(:show, Ability) { false }
    lambda {
      @controller.authorize_resource
    }.should raise_error(CanCan::AccessDenied)
  end
  
  it "should load and authorize resource in one call" do
    mock(@controller).load_resource
    stub(@controller).authorize_resource
    @controller.load_and_authorize_resource
  end
end
