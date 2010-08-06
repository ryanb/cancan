require "spec_helper"

describe CanCan::ControllerResource do
  before(:each) do
    @params = HashWithIndifferentAccess.new(:controller => "abilities")
    @controller = Object.new # simple stub for now
    stub(@controller).params { @params }
  end

  it "should load the resource into an instance variable if params[:id] is specified" do
    @params.merge!(:action => "show", :id => 123)
    stub(Ability).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should not load resource into an instance variable if already set" do
    @params.merge!(:action => "show", :id => 123)
    @controller.instance_variable_set(:@ability, :some_ability)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should properly load resource for namespaced controller" do
    @params.merge!(:controller => "admin/abilities", :action => "show", :id => 123)
    stub(Ability).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should properly load resource for namespaced controller when using '::' for namespace" do
    @params.merge!(:controller => "Admin::AbilitiesController", :action => "show", :id => 123)
    stub(Ability).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should build a new resource with hash if params[:id] is not specified" do
    @params.merge!(:action => "create", :ability => {:foo => "bar"})
    stub(Ability).new("foo" => "bar") { :some_resource }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should build a new resource with no arguments if attribute hash isn't specified" do
    @params[:action] = "new"
    mock(Ability).new { :some_resource }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should not build a resource when on index action" do
    @params[:action] = "index"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end

  it "should perform authorization using controller action and loaded model" do
    @params[:action] = "show"
    @controller.instance_variable_set(:@ability, :some_resource)
    stub(@controller).authorize!(:show, :some_resource) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    lambda { resource.authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should perform authorization using controller action and non loaded model" do
    @params[:action] = "show"
    stub(@controller).authorize!(:show, Ability) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    lambda { resource.authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should call load_resource and authorize_resource for load_and_authorize_resource" do
    @params[:action] = "show"
    resource = CanCan::ControllerResource.new(@controller)
    mock(resource).load_resource
    mock(resource).authorize_resource
    resource.load_and_authorize_resource
  end

  it "should not build a resource when on custom collection action" do
    @params[:action] = "sort"
    resource = CanCan::ControllerResource.new(@controller, :collection => [:sort, :list])
    resource.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end

  it "should build a resource when on custom new action even when params[:id] exists" do
    @params.merge!(:action => "build", :id => 123)
    stub(Ability).new { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :new => :build)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should not try to load resource for other action if params[:id] is undefined" do
    @params[:action] = "list"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should be_nil
  end

  it "should be a parent resource when name is provided which doesn't match controller" do
    resource = CanCan::ControllerResource.new(@controller, :person)
    resource.should be_parent
  end

  it "should not be a parent resource when name is provided which matches controller" do
    resource = CanCan::ControllerResource.new(@controller, :ability)
    resource.should_not be_parent
  end

  it "should be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :ability, {:parent => true})
    resource.should be_parent
  end

  it "should not be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :person, {:parent => false})
    resource.should_not be_parent
  end

  it "should load parent resource through proper id parameter when supplying a resource with a different name" do
    @params.merge!(:action => "index", :person_id => 123)
    stub(Person).find(123) { :some_person }
    resource = CanCan::ControllerResource.new(@controller, :person)
    resource.load_resource
    @controller.instance_variable_get(:@person).should == :some_person
  end

  it "should load parent resource for collection action" do
    @params.merge!(:action => "index", :person_id => 456)
    stub(Person).find(456) { :some_person }
    resource = CanCan::ControllerResource.new(@controller, :person)
    resource.load_resource
    @controller.instance_variable_get(:@person).should == :some_person
  end

  it "should load resource through the association of another parent resource" do
    @params.merge!(:action => "show", :id => 123)
    person = Object.new
    @controller.instance_variable_set(:@person, person)
    stub(person).abilities.stub!.find(123) { :some_ability }
    resource = CanCan::ControllerResource.new(@controller, :through => :person)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should not load through parent resource if instance isn't loaded" do
    @params.merge!(:action => "show", :id => 123)
    stub(Ability).find(123) { :some_ability }
    resource = CanCan::ControllerResource.new(@controller, :through => :person)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should load through first matching if multiple are given" do
    @params.merge!(:action => "show", :id => 123)
    person = Object.new
    @controller.instance_variable_set(:@person, person)
    stub(person).abilities.stub!.find(123) { :some_ability }
    resource = CanCan::ControllerResource.new(@controller, :through => [:thing, :person])
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should find record through has_one association with :singleton option" do
    @params.merge!(:action => "show")
    person = Object.new
    @controller.instance_variable_set(:@person, person)
    stub(person).ability { :some_ability }
    resource = CanCan::ControllerResource.new(@controller, :through => :person, :singleton => true)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_ability
  end

  it "should build record through has_one association with :singleton option" do
    @params.merge!(:action => "create", :ability => :ability_attributes)
    person = Object.new
    @controller.instance_variable_set(:@person, person)
    stub(person).build_ability(:ability_attributes) { :new_ability }
    resource = CanCan::ControllerResource.new(@controller, :through => :person, :singleton => true)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :new_ability
  end

  it "should only authorize :read action on parent resource" do
    @params.merge!(:action => "new", :person_id => 123)
    stub(Person).find(123) { :some_person }
    stub(@controller).authorize!(:read, :some_person) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :person)
    lambda { resource.load_and_authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should load the model using a custom class" do
    @params.merge!(:action => "show", :id => 123)
    stub(Person).find(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :class => Person)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should authorize based on resource name if class is false" do
    @params.merge!(:action => "show", :id => 123)
    stub(@controller).authorize!(:show, :ability) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :class => false)
    lambda { resource.authorize_resource }.should raise_error(CanCan::AccessDenied)
  end

  it "should load and authorize using custom instance name" do
    @params.merge!(:action => "show", :id => 123)
    stub(Ability).find(123) { :some_ability }
    stub(@controller).authorize!(:show, :some_ability) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :instance_name => :custom_ability)
    lambda { resource.load_and_authorize_resource }.should raise_error(CanCan::AccessDenied)
    @controller.instance_variable_get(:@custom_ability).should == :some_ability
  end

  it "should load resource using custom find_by attribute" do
    @params.merge!(:action => "show", :id => 123)
    stub(Ability).find_by_name!(123) { :some_resource }
    resource = CanCan::ControllerResource.new(@controller, :find_by => :name)
    resource.load_resource
    @controller.instance_variable_get(:@ability).should == :some_resource
  end

  it "should raise ImplementationRemoved when adding :name option" do
    lambda {
      CanCan::ControllerResource.new(@controller, :name => :foo)
    }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "should raise ImplementationRemoved exception when specifying :resource option since it is no longer used" do
    lambda {
      CanCan::ControllerResource.new(@controller, :resource => Person)
    }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "should raise ImplementationRemoved exception when passing :nested option" do
    lambda {
      CanCan::ControllerResource.new(@controller, :nested => :person)
    }.should raise_error(CanCan::ImplementationRemoved)
  end
end
