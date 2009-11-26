require File.dirname(__FILE__) + '/../spec_helper'

describe CanCan::ResourceAuthorization do
  before(:each) do
    @controller = Object.new # simple stub for now
    stub(@controller).unauthorized! { raise CanCan::AccessDenied }
  end
  
  it "should load the resource into an instance variable if params[:id] is specified" do
    stub(Ability).find(123) { :some_resource }
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "show", :id => 123)
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should properly load resource for namespaced controller" do
    stub(Ability).find(123) { :some_resource }
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "admin/abilities", :action => "show", :id => 123)
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should build a new resource with hash if params[:id] is not specified" do
    stub(Ability).new(:foo => "bar") { :some_resource }
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "create", :ability => {:foo => "bar"})
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should build a new resource even if attribute hash isn't specified" do
    stub(Ability).new(nil) { :some_resource }
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "new")
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should not build a resource when on index action" do
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "index")
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end
  
  it "should perform authorization using controller action and loaded model" do
    @controller.instance_variable_set(:@ability, :some_resource)
    stub(@controller).cannot?(:show, :some_resource) { true }
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "show")
    lambda {
      authorization.authorize_resource
    }.should raise_error(CanCan::AccessDenied)
  end
  
  it "should perform authorization using controller action and non loaded model" do
    stub(@controller).cannot?(:show, Ability) { true }
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "show")
    lambda {
      authorization.authorize_resource
    }.should raise_error(CanCan::AccessDenied)
  end
end
