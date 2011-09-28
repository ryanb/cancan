require "spec_helper"

describe CanCan::ControllerResource do
  before(:each) do
    @params = HashWithIndifferentAccess.new(:controller => "projects")
    @controller_class = Class.new
    @controller = @controller_class.new
    @ability = Ability.new(nil)
    stub(@controller).params { @params }
    stub(@controller).current_ability { @ability }
    stub(@controller).authorize! { |*args| @ability.authorize!(*args) }
    # stub(@controller_class).cancan_skipper { {:authorize => {}, :load => {}} }
  end

  it "should load the resource into an instance variable if params[:id] is specified" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should not load resource into an instance variable if already set" do
    @params.merge!(:action => "show", :id => 123)
    @controller.instance_variable_set(:@project, :some_project)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should properly load resource for namespaced controller" do
    project = Project.create!
    @params.merge!(:controller => "admin/projects", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should properly load resource for namespaced controller when using '::' for namespace" do
    project = Project.create!
    @params.merge!(:controller => "Admin::ProjectsController", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should build a new resource with hash if params[:id] is not specified and authorize on each attribute" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "should build a new resource with attributes from current ability" do
    @params.merge!(:action => "new")
    @ability.can(:create, :projects, :name => "from conditions")
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "from conditions"
  end

  it "should override initial attributes with params" do
    @params.merge!(:action => "new", :project => {:name => "from params"})
    @ability.can(:create, :projects, :name => "from conditions")
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "from params"
  end

  it "should build a collection when on index action when class responds to accessible_by and mark ability as fully authorized" do
    stub(Project).accessible_by(@ability, :index) { :found_projects }
    @params[:action] = "index"
    CanCan::ControllerResource.new(@controller, :project, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_get(:@projects).should == :found_projects
    @ability.should be_fully_authorized(:index, :projects)
  end

  it "should not build a collection when on index action when class does not respond to accessible_by and not mark ability as fully authorized" do
    @params[:action] = "index"
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_defined?(:@projects).should be_false
    @ability.should_not be_fully_authorized(:index, :projects)
  end

  it "should not use accessible_by when defining abilities through a block" do
    stub(Project).accessible_by(@ability) { :found_projects }
    @params[:action] = "index"
    @ability.can(:read, :projects) { |p| false }
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_defined?(:@projects).should be_false
  end

  it "should not authorize resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@project, :some_project)
    stub(@controller).authorize!(:index, :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end

  it "should authorize parent resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@category, :some_category)
    stub(@controller).authorize!(:show, :some_category) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :category, :parent => true, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should perform authorization using controller action and loaded model" do
    @params.merge!(:action => "show", :id => 123)
    @controller.instance_variable_set(:@project, :some_project)
    stub(@controller).authorize!(:show, :some_project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should not perform authorization using controller action when no loaded model" do
    @params.merge!(:action => "show", :id => 123)
    stub(@controller).authorize!(:show, :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end

  it "should not build a single resource when on custom collection action even with id" do
    @params.merge!(:action => "sort", :id => 123)
    CanCan::ControllerResource.new(@controller, :load => true, :collection => [:sort, :list]).process
    @controller.instance_variable_get(:@project).should be_nil
  end

  it "should load a collection resource when on custom action with no id param" do
    stub(Project).accessible_by(@ability, :sort) { :found_projects }
    @params[:action] = "sort"
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_get(:@projects).should == :found_projects
  end

  it "should build a resource when on custom new action even when params[:id] exists" do
    @params.merge!(:action => "build", :id => 123)
    stub(Project).new { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :new => :build).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should not try to load resource for other action if params[:id] is undefined" do
    @params[:action] = "list"
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
  end

  it "should be a parent resource when name is provided which doesn't match controller" do
    resource = CanCan::ControllerResource.new(@controller, :category)
    resource.should be_parent
  end

  it "should not be a parent resource when name is provided which matches controller" do
    resource = CanCan::ControllerResource.new(@controller, :project)
    resource.should_not be_parent
  end

  it "should be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :project, {:parent => true})
    resource.should be_parent
  end

  it "should not be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :category, {:parent => false})
    resource.should_not be_parent
  end

  it "should load parent resource through proper id parameter" do
    project = Project.create!
    @params.merge!(:action => "index", :project_id => project.id)
    CanCan::ControllerResource.new(@controller, :project, :load => true, :parent => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should load resource through the association of another parent resource using instance variable" do
    @params.merge!(:action => "show", :id => 123)
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    stub(category).projects.stub!.find(123) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should load resource through the custom association name" do
    @params.merge!(:action => "show", :id => 123)
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    stub(category).custom_projects.stub!.find(123) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :through_association => :custom_projects).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should load resource through the association of another parent resource using method" do
    @params.merge!(:action => "show", :id => 123)
    category = Object.new
    stub(@controller).category { category }
    stub(category).projects.stub!.find(123) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should not load through parent resource if instance isn't loaded when shallow" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :shallow => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should raise Unauthorized when attempting to load resource through nil" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :load => true, :through => :category)
    lambda {
      resource.process
    }.should raise_error(CanCan::Unauthorized) { |exception|
      exception.action.should == :show
      exception.subject.should == :projects
    }
    @controller.instance_variable_get(:@project).should be_nil
  end

  it "should authorize nested resource through parent association on index action" do
    pending
    @params.merge!(:action => "index")
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    stub(@controller).authorize!(:index, category => :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true, :through => :category)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should load through first matching if multiple are given" do
    @params.merge!(:action => "show", :id => 123)
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    stub(category).projects.stub!.find(123) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => [:category, :user]).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should find record through has_one association with :singleton option without id param" do
    @params.merge!(:action => "show", :id => nil)
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    stub(category).project { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "should not build record through has_one association with :singleton option because it can cause it to delete it in the database" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    category = Category.new
    @controller.instance_variable_set(:@category, category)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
    @controller.instance_variable_get(:@project).category.should == category
  end

  it "should find record through has_one association with :singleton and :shallow options" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true, :shallow => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should build record through has_one association with :singleton and :shallow options" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true, :shallow => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "should only authorize :show action on parent resource" do
    project = Project.create!
    @params.merge!(:action => "new", :project_id => project.id)
    stub(@controller).authorize!(:show, project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :project, :load => true, :authorize => true, :parent => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should authorize update action before setting attributes" do
    @ability.can :update, :projects, :name => "bar"
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "update", :id => project.id, :project => {:name => "bar"})
    resource = CanCan::ControllerResource.new(@controller, :project, :load => true, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should authorize update action after setting attributes" do
    @ability.can :update, :projects, :name => "foo"
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "update", :id => project.id, :project => {:name => "bar"})
    resource = CanCan::ControllerResource.new(@controller, :project, :load => true, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should load the model using a custom class" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :class => Project).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should not authorize based on resource name if class is false because we don't do class level authorization anymore" do
    @params.merge!(:action => "show", :id => 123)
    stub(@controller).authorize!(:show, :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true, :class => false)
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end

  it "should load and authorize using custom instance name" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    stub(@controller).authorize!(:show, project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :load => true, :authorize => true, :instance_name => :custom_project)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
    @controller.instance_variable_get(:@custom_project).should == project
  end

  it "should load resource using custom ID param" do
    project = Project.create!
    @params.merge!(:action => "show", :the_project => project.id)
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project, :load => true)
    resource.process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should load resource using custom find_by attribute" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    CanCan::ControllerResource.new(@controller, :load => true, :find_by => :name).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should authorize each new attribute in the create action" do
    @params.merge!(:action => "create", :project => {:name => "foo"})
    @controller.instance_variable_set(:@project, :some_project)
    mock(@controller).authorize!(:create, :some_project, :name)
    CanCan::ControllerResource.new(@controller, :authorize => true).process
  end

  it "should allow full find method to be passed into find_by option" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    CanCan::ControllerResource.new(@controller, :find_by => :find_by_name, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "should authorize each new attribute in the update action" do
    @params.merge!(:action => "update", :id => 123, :project => {:name => "foo"})
    @controller.instance_variable_set(:@project, :some_project)
    mock(@controller).authorize!(:update, :some_project, :name)
    CanCan::ControllerResource.new(@controller, :authorize => true).process
  end

  it "should fetch member through method when instance variable is not provided" do
    stub(@controller).project { :some_project }
    @params.merge!(:action => "show", :id => 123)
    stub(@controller).authorize!(:show, :some_project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "should attempt to load a resource with the same namespace as the controller when using :: for namespace" do
    module Namespaced
      class Project < ::Project; end
    end
    project = Namespaced::Project.create!
    @params.merge!(:controller => "Namespaced::ProjectsController", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  # Rails includes namespace in params, see issue #349
  it "should create through namespaced params" do
    module Namespaced
      class Project < ::Project; end
    end
    @params.merge!(:controller => "Namespaced::ProjectsController", :action => "create", :namespaced_project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  # it "should raise ImplementationRemoved when adding :name option" do
  #   lambda {
  #     CanCan::ControllerResource.new(@controller, :name => :foo)
  #   }.should raise_error(CanCan::ImplementationRemoved)
  # end
  #
  # it "should raise ImplementationRemoved exception when specifying :resource option since it is no longer used" do
  #   lambda {
  #     CanCan::ControllerResource.new(@controller, :resource => Project)
  #   }.should raise_error(CanCan::ImplementationRemoved)
  # end
  #
  # it "should raise ImplementationRemoved exception when passing :nested option" do
  #   lambda {
  #     CanCan::ControllerResource.new(@controller, :nested => :project)
  #   }.should raise_error(CanCan::ImplementationRemoved)
  # end

  # it "should skip resource behavior for :only actions in array" do
  #   stub(@controller_class).cancan_skipper { {:load => {nil => {:only => [:index, :show]}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_true
  #   CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load).should be_false
  #   @params.merge!(:action => "show")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_true
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_false
  # end
  #
  # it "should skip resource behavior for :only one action on resource" do
  #   stub(@controller_class).cancan_skipper { {:authorize => {:project => {:only => :index}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller).skip?(:authorize).should be_false
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_true
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_false
  # end
  #
  # it "should skip resource behavior :except actions in array" do
  #   stub(@controller_class).cancan_skipper { {:load => {nil => {:except => [:index, :show]}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_false
  #   @params.merge!(:action => "show")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_false
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_true
  #   CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load).should be_false
  # end
  #
  # it "should skip resource behavior :except one action on resource" do
  #   stub(@controller_class).cancan_skipper { {:authorize => {:project => {:except => :index}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_false
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller).skip?(:authorize).should be_false
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_true
  # end
  #
  # it "should skip loading and authorization" do
  #   stub(@controller_class).cancan_skipper { {:authorize => {nil => {}}, :load => {nil => {}}} }
  #   @params.merge!(:action => "new")
  #   resource = CanCan::ControllerResource.new(@controller)
  #   lambda { resource.load_and_authorize_resource }.should_not raise_error
  #   @controller.instance_variable_get(:@project).should be_nil
  # end
end
