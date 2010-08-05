require "spec_helper"

describe CanCan::ControllerResource do
  before(:each) do
    @controller = Object.new # simple stub for now
  end

  it "should load the resource into an instance variable if params[:id] is specified" do
    stub(Ability).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "show", :id => 123)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should not load resource into an instance variable if already set" do
    @controller.instance_variable_set(:@ability, :some_ability)
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "show", :id => 123)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should properly load resource for namespaced controller" do
    stub(Ability).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :controller => "admin/abilities", :action => "show", :id => 123)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should properly load resource for namespaced controller when using '::' for namespace" do
    stub(Ability).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :controller => "Admin::AbilitiesController", :action => "show", :id => 123)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should build a new resource with hash if params[:id] is not specified" do
    stub(Ability).new(:foo => "bar") { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "create", :ability => {:foo => "bar"})
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should build a new resource even if attribute hash isn't specified" do
    stub(Ability).new(nil) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "new")
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should not build a resource when on index action" do
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "index")
    resource.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end

  it "should perform authorization using controller action and loaded model" do
    @controller.instance_variable_set(:@ability, :some_resource)
    stub(@controller).authorize!(:show, :some_resource) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "show")
    lambda { resource.authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should perform authorization using controller action and non loaded model" do
    stub(@controller).authorize!(:show, Ability) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "show")
    lambda { resource.authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should call load_resource and authorize_resource for load_and_authorize_resource" do
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "show")
    mock(resource).load_resource
    mock(resource).authorize_resource
    resource.load_and_authorize_resource
  end

  it "should not build a resource when on custom collection action" do
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "sort"}, {:collection => [:sort, :list]})
    resource.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end

  it "should build a resource when on custom new action even when params[:id] exists" do
    stub(Ability).new(nil) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "build", :id => 123}, {:new => :build})
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should not try to load resource for other action if params[:id] is undefined" do
    resource = CanCan::ControllerResource.new(@controller, :controller => "abilities", :action => "list")
    resource.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end

  it "should be a parent resource when name is provided which doesn't match controller" do
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities"}, :person)
    resource.should be_parent
  end

  it "should not be a parent resource when name is provided which matches controller" do
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities"}, :ability)
    resource.should_not be_parent
  end

  it "should be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities"}, :ability, {:parent => true})
    resource.should be_parent
  end

  it "should load parent resource through proper id parameter when supplying a resource with a different name" do
    stub(Person).find(123) { :some_person }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "index", :person_id => 123}, :person)
    resource.load_resource
    @controller.instance_variable_get(:@person).should == :some_person
  end

  it "should load parent resource for collection action" do
    stub(Person).find(456) { :some_person }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "index", :person_id => 456}, :person)
    resource.load_resource
    @controller.instance_variable_get(:@person).should == :some_person
  end

  it "should load resource through the association of another parent resource" do
    person = Object.new
    @controller.instance_variable_set(:@person, person)
    stub(person).abilities.stub!.find(123) { :some_ability }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "show", :id => 123}, {:through => :person})
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should not load through parent resource if instance isn't loaded" do
    stub(Ability).find(123) { :some_ability }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "show", :id => 123}, {:through => :person})
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should only authorize :read action on parent resource" do
    stub(Person).find(123) { :some_person }
    stub(@controller).authorize!(:read, :some_person) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "new", :person_id => 123}, :person)
    lambda { resource.load_and_authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should load the model using a custom class" do
    stub(Person).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "show", :id => 123}, {:class => Person})
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should authorize based on resource name if class is false" do
    stub(@controller).authorize!(:show, :ability) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, {:controller => "abilities", :action => "show", :id => 123}, {:class => false})
    lambda { resource.authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should raise ImplementationRemoved when adding :name option" do
    lambda {
      CanCan::ControllerResource.new(@controller, {}, {:name => :foo})
    }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "should raise ImplementationRemoved exception when specifying :resource option since it is no longer used" do
    lambda {
      CanCan::ControllerResource.new(@controller, {}, {:resource => Person})
    }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "should raise ImplementationRemoved exception when passing :nested option" do
    lambda {
      CanCan::ControllerResource.new(@controller, {}, {:nested => :person})
    }.should raise_error(CanCan::ImplementationRemoved)
  end
end
