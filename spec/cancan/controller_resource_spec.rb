require "spec_helper"

describe CanCan::ControllerResource do
  before(:each) do
    Project.delete_all
    Category.delete_all
    @params = HashWithIndifferentAccess.new(:controller => "projects")
    @controller_class = Class.new
    @controller = @controller_class.new
    @ability = Ability.new(nil)
    @controller.stub(:params) { @params }
    @controller.stub(:current_ability) { @ability }
    @controller.stub(:authorize!) { |*args| @ability.authorize!(*args) }
    # @controller_class.stub(:cancan_skipper) { {:authorize => {}, :load => {}} }
  end

  it "loads the resource into an instance variable if params[:id] is specified" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "does not load resource into an instance variable if already set" do
    @params.merge!(:action => "show", :id => 123)
    @controller.instance_variable_set(:@project, :some_project)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "loads resource for namespaced controller" do
    project = Project.create!
    @params.merge!(:controller => "admin/projects", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "attempts to load a resource with the same namespace as the controller when using :: for namespace" do
    module SomeEngine
      class Project < ::Project; end
    end
    project = SomeEngine::Project.create!
    @params.merge!(:controller => "SomeEngine::ProjectsController", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  # Rails includes namespace in params, see issue #349
  it "creates through the namespaced params" do
    module SomeEngine
      class Project < ::Project; end
    end
    @params.merge!(:controller => "SomeEngine::ProjectsController", :action => "create", :some_engine_project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "loads resource for namespaced controller when using '::' for namespace" do
    project = Project.create!
    @params.merge!(:controller => "Admin::ProjectsController", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "has the specified nested resource_class when using / for namespace" do
    module Admin
      class Dashboard; end
    end
    @ability.can(:index, "admin/dashboard")
    @params.merge!(:controller => "admin/dashboard", :action => "index")
    @controller.authorize!(:index, "admin/dashboard")
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    resource.send(:resource_class).should == Admin::Dashboard
  end

  it "builds a new resource with hash if params[:id] is not specified and authorize on each attribute" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "builds a new resource for namespaced model with hash if params[:id] is not specified" do
    module SomeEngine
      class Project < ::Project; end
    end
    @params.merge!(:action => "create", :some_engine_project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true, :class => SomeEngine::Project).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "builds a new resource with attributes from current ability" do
    @params.merge!(:action => "new")
    @ability.can(:create, :projects, :name => "from conditions")
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "from conditions"
  end

  it "overrides initial attributes with params" do
    @params.merge!(:action => "new", :project => {:name => "from params"})
    @ability.can(:create, :projects, :name => "from conditions")
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "from params"
  end

  it "builds a collection when on index action when class responds to accessible_by and mark ability as fully authorized" do
    Project.stub(:accessible_by).with(@ability, :index) { :found_projects }
    @params[:action] = "index"
    CanCan::ControllerResource.new(@controller, :project, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_get(:@projects).should == :found_projects
    @ability.should be_fully_authorized(:index, :projects)
  end

  it "does not build a collection when on index action when class does not respond to accessible_by and not mark ability as fully authorized" do
    class CustomModel
    end
    @params[:controller] = "custom_models"
    @params[:action] = "index"
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_defined?(:@projects).should be_false
    @ability.should_not be_fully_authorized(:index, :projects)
  end

  it "does not use accessible_by when defining abilities through a block" do
    Project.stub(:accessible_by).with(@ability) { :found_projects }
    @params[:action] = "index"
    @ability.can(:read, :projects) { |p| false }
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_defined?(:@projects).should be_false
  end

  it "does not authorize resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@project, :some_project)
    @controller.stub(:authorize!).with(:index, :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end

  it "authorizes parent resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@category, :some_category)
    @controller.stub(:authorize!).with(:show, :some_category) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :category, :parent => true, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "performs authorization using controller action and loaded model" do
    @params.merge!(:action => "show", :id => 123)
    @controller.instance_variable_set(:@project, :some_project)
    @controller.stub(:authorize!).with(:show, :some_project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "does not perform authorization using controller action when no loaded model" do
    @params.merge!(:action => "show", :id => 123)
    @controller.stub(:authorize!).with(:show, :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end

  it "does not build a single resource when on custom collection action even with id" do
    @params.merge!(:action => "sort", :id => 123)
    CanCan::ControllerResource.new(@controller, :load => true, :collection => [:sort, :list]).process
    @controller.instance_variable_get(:@project).should be_nil
  end

  it "loads a collection resource when on custom action with no id param" do
    Project.stub(:accessible_by).with(@ability, :sort) { :found_projects }
    @params[:action] = "sort"
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
    @controller.instance_variable_get(:@projects).should == :found_projects
  end

  it "builds a resource when on custom new action even when params[:id] exists" do
    @params.merge!(:action => "build", :id => 123)
    Project.stub(:new) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :new => :build).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "does not try to load resource for other action if params[:id] is undefined" do
    @params[:action] = "list"
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should be_nil
  end

  it "is a parent resource when name is provided which doesn't match controller" do
    resource = CanCan::ControllerResource.new(@controller, :category)
    resource.should be_parent
  end

  it "does not be a parent resource when name is provided which matches controller" do
    resource = CanCan::ControllerResource.new(@controller, :project)
    resource.should_not be_parent
  end

  it "is parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :project, {:parent => true})
    resource.should be_parent
  end

  it "does not be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :category, {:parent => false})
    resource.should_not be_parent
  end

  it "has the specified resource_class if name is passed to load_resource" do
    resource = CanCan::ControllerResource.new(@controller, :category)
    resource.send(:resource_class).should == Category
  end

  it "loads parent resource through proper id parameter" do
    project = Project.create!
    @params.merge!(:action => "index", :project_id => project.id)
    CanCan::ControllerResource.new(@controller, :project, :load => true, :parent => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "loads resource through the association of another parent resource using instance variable" do
    @params.merge!(:action => "show", :id => 123)
    category = double("category", :projects => double("projects"))
    category.projects.stub(:find).with(123) { :some_project }
    @controller.instance_variable_set(:@category, category)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "loads resource through the custom association name" do
    @params.merge!(:action => "show", :id => 123)
    category = double("category", :custom_projects => double("custom_projects"))
    category.custom_projects.stub(:find).with(123) { :some_project }
    @controller.instance_variable_set(:@category, category)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :through_association => :custom_projects).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "loads resource through the association of another parent resource using method" do
    @params.merge!(:action => "show", :id => 123)
    category = double("category", :projects => double("projects"))
    @controller.stub(:category) { category }
    category.projects.stub(:find).with(123) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "does not load through parent resource if instance isn't loaded when shallow" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :shallow => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "raises Unauthorized when attempting to load resource through nil" do
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

  it "named resources should be loaded independently of the controller name" do
    category = Category.create!
    @params.merge!(:action => "new", :category_id => category.id)
    CanCan::ControllerResource.new(@controller, :category, :load => true).process
    CanCan::ControllerResource.new(@controller, :project, :load => true, :through => :category).process
    @controller.instance_variable_get(:@category).should eq(category)
    project = @controller.instance_variable_get(:@project)
    project.category.should eq(category)
  end

  it "parent resources shouldn't be altered" do
    category = Category.create!
    @params.merge!(:action => "create", :category_id => category.id, :project => { :name => 'foo' })
    CanCan::ControllerResource.new(@controller, :category, :load => true).process
    CanCan::ControllerResource.new(@controller, :project, :load => true, :through => :category).process
    project = @controller.instance_variable_get(:@project)
    project.new_record?.should eq(true)
    project.name.should eq('foo')
  end

  it "authorizes nested resource through parent association on index action" do
    pending
    @params.merge!(:action => "index")
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    @controller.stub(:authorize!).with(:index, category => :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true, :through => :category)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "loads through first matching if multiple are given" do
    @params.merge!(:action => "show", :id => 123)
    category = double("category", :projects => double("projects"))
    category.projects.stub(:find).with(123) { :some_project }
    @controller.instance_variable_set(:@category, category)
    CanCan::ControllerResource.new(@controller, :load => true, :through => [:category, :user]).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "finds record through has_one association with :singleton option without id param" do
    @params.merge!(:action => "show", :id => nil)
    category = Object.new
    @controller.instance_variable_set(:@category, category)
    category.stub(:project) { :some_project }
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true).process
    @controller.instance_variable_get(:@project).should == :some_project
  end

  it "does not build record through has_one association with :singleton option because it can cause it to delete it in the database" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    category = Category.new
    @controller.instance_variable_set(:@category, category)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
    @controller.instance_variable_get(:@project).category.should == category
  end

  it "finds record through has_one association with :singleton and :shallow options" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true, :shallow => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "builds record through has_one association with :singleton and :shallow options" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true, :through => :category, :singleton => true, :shallow => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "only authorizes :show action on parent resource" do
    project = Project.create!
    @params.merge!(:action => "new", :project_id => project.id)
    @controller.stub(:authorize!).with(:show, project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :project, :load => true, :authorize => true, :parent => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "authorizes update action before setting attributes" do
    @ability.can :update, :projects, :name => "bar"
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "update", :id => project.id, :project => {:name => "bar"})
    resource = CanCan::ControllerResource.new(@controller, :project, :load => true, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "authorizes update action after setting attributes" do
    @ability.can :update, :projects, :name => "foo"
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "update", :id => project.id, :project => {:name => "bar"})
    resource = CanCan::ControllerResource.new(@controller, :project, :load => true, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "loads the model using a custom class" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :class => Project).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "loads the model using a custom namespaced class" do
    module SomeEngine
      class Project < ::Project; end
    end
    project = SomeEngine::Project.create!
    @params.merge!(:action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true, :class => SomeEngine::Project).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "does not authorize based on resource name if class is false because we don't do class level authorization anymore" do
    @params.merge!(:action => "show", :id => 123)
    @controller.stub(:authorize!).with(:show, :projects) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true, :class => false)
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end

  it "loads and authorize using custom instance name" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    @controller.stub(:authorize!).with(:show, project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :load => true, :authorize => true, :instance_name => :custom_project)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
    @controller.instance_variable_get(:@custom_project).should == project
  end

  it "loads resource using custom ID param" do
    project = Project.create!
    @params.merge!(:action => "show", :the_project => project.id)
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project, :load => true)
    resource.process
    @controller.instance_variable_get(:@project).should == project
  end

  it "loads resource using custom find_by attribute" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    CanCan::ControllerResource.new(@controller, :load => true, :find_by => :name).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "authorizes each new attribute in the create action" do
    @params.merge!(:action => "create", :project => {:name => "foo"})
    @controller.instance_variable_set(:@project, :some_project)
    @ability.should_receive(:authorize!).with(:create, :some_project, :name)
    CanCan::ControllerResource.new(@controller, :authorize => true).process
  end

  it "allows full find method to be passed into find_by option" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    CanCan::ControllerResource.new(@controller, :find_by => :find_by_name, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  it "authorizes each new attribute in the update action" do
    @params.merge!(:action => "update", :id => 123, :project => {:name => "foo"})
    @controller.instance_variable_set(:@project, :some_project)
    @ability.should_receive(:authorize!).with(:update, :some_project, :name)
    CanCan::ControllerResource.new(@controller, :authorize => true).process
  end

  it "fetches member through method when instance variable is not provided" do
    @controller.stub(:project) { :some_project }
    @params.merge!(:action => "show", :id => 123)
    @controller.stub(:authorize!).with(:show, :some_project) { raise CanCan::Unauthorized }
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    lambda { resource.process }.should raise_error(CanCan::Unauthorized)
  end

  it "attempts to load a resource with the same namespace as the controller when using :: for namespace" do
    module Namespaced
      class Project < ::Project; end
    end
    project = Namespaced::Project.create!
    @params.merge!(:controller => "Namespaced::ProjectsController", :action => "show", :id => project.id)
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).should == project
  end

  # Rails includes namespace in params, see issue #349
  it "creates through namespaced params" do
    module Namespaced
      class Project < ::Project; end
    end
    @params.merge!(:controller => "Namespaced::ProjectsController", :action => "create", :namespaced_project => {:name => "foobar"})
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "should properly authorize resource for namespaced controller" do
    @ability.can(:index, "admin/dashboard")
    @params.merge!(:controller => "admin/dashboard", :action => "index")
    @controller.authorize!(:index, "admin/dashboard")
    resource = CanCan::ControllerResource.new(@controller, :authorize => true).process
    lambda { resource.process }.should_not raise_error(CanCan::Unauthorized)
  end
  
  it "should attempt pre-processing by default if strong_parameters are used" do
    class ActionController
      class Parameters < HashWithIndifferentAccess
      end
    end

    @params.merge!(:action => "create")
    @controller.class.send(:define_method, :project_params) do { :name => 'foobar'} end
    CanCan::ControllerResource.new(@controller, :load => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  
    class ActionController
      remove_const :Parameters
    end
  end

  it "should allow controller methods for parameter pre-processing" do
    @params.merge!(:action => "create")
    @controller.class.send(:define_method, :project_parameters) do { :name => 'foobar'} end
    CanCan::ControllerResource.new(@controller, :load => true, :params => :project_parameters).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  it "should revert back to parameters if the method does not exist within the controller" do
    @params.merge!(:action => "create", :project => { name: 'foobar' })
    CanCan::ControllerResource.new(@controller, :load => true, :params => true).process
    @controller.instance_variable_get(:@project).name.should == "foobar"
  end

  # it "raises ImplementationRemoved when adding :name option" do
  #   lambda {
  #     CanCan::ControllerResource.new(@controller, :name => :foo)
  #   }.should raise_error(CanCan::ImplementationRemoved)
  # end
  #
  # it "raises ImplementationRemoved exception when specifying :resource option since it is no longer used" do
  #   lambda {
  #     CanCan::ControllerResource.new(@controller, :resource => Project)
  #   }.should raise_error(CanCan::ImplementationRemoved)
  # end
  #
  # it "raises ImplementationRemoved exception when passing :nested option" do
  #   lambda {
  #     CanCan::ControllerResource.new(@controller, :nested => :project)
  #   }.should raise_error(CanCan::ImplementationRemoved)
  # end

  # it "skips resource behavior for :only actions in array" do
  #   @controller_class.stub(:cancan_skipper) { {:load => {nil => {:only => [:index, :show]}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_true
  #   CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load).should be_false
  #   @params.merge!(:action => "show")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_true
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_false
  # end
  #
  # it "skips resource behavior for :only one action on resource" do
  #   @controller_class.stub(:cancan_skipper) { {:authorize => {:project => {:only => :index}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller).skip?(:authorize).should be_false
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_true
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_false
  # end
  #
  # it "skips resource behavior :except actions in array" do
  #   @controller_class.stub(:cancan_skipper) { {:load => {nil => {:except => [:index, :show]}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_false
  #   @params.merge!(:action => "show")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_false
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller).skip?(:load).should be_true
  #   CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load).should be_false
  # end
  #
  # it "skips resource behavior :except one action on resource" do
  #   @controller_class.stub(:cancan_skipper) { {:authorize => {:project => {:except => :index}}} }
  #   @params.merge!(:action => "index")
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_false
  #   @params.merge!(:action => "other_action")
  #   CanCan::ControllerResource.new(@controller).skip?(:authorize).should be_false
  #   CanCan::ControllerResource.new(@controller, :project).skip?(:authorize).should be_true
  # end
  #
  # it "skips loading and authorization" do
  #   @controller_class.stub(:cancan_skipper) { {:authorize => {nil => {}}, :load => {nil => {}}} }
  #   @params.merge!(:action => "new")
  #   resource = CanCan::ControllerResource.new(@controller)
  #   lambda { resource.load_and_authorize_resource }.should_not raise_error
  #   @controller.instance_variable_get(:@project).should be_nil
  # end
end
