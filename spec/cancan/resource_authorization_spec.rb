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
  
  it "should call load_resource and authorize_resource for load_and_authorize_resource" do
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "show")
    mock(authorization).load_resource
    mock(authorization).authorize_resource
    authorization.load_and_authorize_resource
  end
  
  it "should not build a resource when on custom collection action" do
    authorization = CanCan::ResourceAuthorization.new(@controller, {:controller => "abilities", :action => "sort"}, {:collection => [:sort, :list]})
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end
  
  it "should build a resource when on custom new action even when params[:id] exists" do
    stub(Ability).new(nil) { :some_resource }
    authorization = CanCan::ResourceAuthorization.new(@controller, {:controller => "abilities", :action => "build", :id => 123}, {:new => :build})
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
  
  it "should not try to load resource for other action if params[:id] is undefined" do
    authorization = CanCan::ResourceAuthorization.new(@controller, :controller => "abilities", :action => "list")
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end
  
  it "should load nested resource and fetch other resource through the association" do
    stub(Person).find(456).stub!.abilities.stub!.find(123) { :some_ability }
    authorization = CanCan::ResourceAuthorization.new(@controller, {:controller => "abilities", :action => "show", :id => 123, :person_id => 456}, {:nested => :person})
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should load nested resource and build resource through a deep association" do
    stub(Person).find(456).stub!.behaviors.stub!.find(789).stub!.abilities.stub!.build(nil) { :some_ability }
    authorization = CanCan::ResourceAuthorization.new(@controller, {:controller => "abilities", :action => "new", :person_id => 456, :behavior_id => 789}, {:nested => [:person, :behavior]})
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should not load nested resource and build through this if *_id param isn't specified" do
    stub(Person).find(456) { :some_person }
    stub(Ability).new(nil) { :some_ability }
    authorization = CanCan::ResourceAuthorization.new(@controller, {:controller => "abilities", :action => "new", :person_id => 456}, {:nested => [:person, :behavior]})
    authorization.load_resource
    @controller.instance_variable_get(:@person).should == :some_person
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should load the model using a custom class" do
    stub(Person).find(123) { :some_resource }
    authorization = CanCan::ResourceAuthorization.new(@controller, {:controller => "abilities", :action => "show", :id => 123}, {:class => Person})
    authorization.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
end
