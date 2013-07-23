require "spec_helper"

describe CanCan::ControllerResource do
  before(:each) do
    @params = HashWithIndifferentAccess.new(:controller => "projects")
    @controller_class = Class.new
    @controller = @controller_class.new
    @ability = Ability.new(nil)
    allow(@controller).to receive(:params) { @params }
    allow(@controller).to receive(:current_ability) { @ability }
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {}, :load => {}} }
  end

  it "should load the resource into an instance variable if params[:id] is specified" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should not load resource into an instance variable if already set" do
    @params.merge!(:action => "show", :id => "123")
    @controller.instance_variable_set(:@project, :some_project)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should properly load resource for namespaced controller" do
    project = Project.create!
    @params.merge!(:controller => "admin/projects", :action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should attempt to load a resource with the same namespace as the controller when using :: for namespace" do
    module MyEngine
      class Project < ::Project; end
    end

    project = MyEngine::Project.create!
    @params.merge!(:controller => "MyEngine::ProjectsController", :action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  # Rails includes namespace in params, see issue #349
  it "should create through the namespaced params" do
    module MyEngine
      class Project < ::Project; end
    end

    @params.merge!(:controller => "MyEngine::ProjectsController", :action => "create", :my_engine_project => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "should properly load resource for namespaced controller when using '::' for namespace" do
    project = Project.create!
    @params.merge!(:controller => "Admin::ProjectsController", :action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "has the specified nested resource_class when using / for namespace" do
    module Admin
      class Dashboard; end
    end
    @ability.can(:index, "admin/dashboard")
    @params.merge!(:controller => "admin/dashboard", :action => "index")
    resource = CanCan::ControllerResource.new(@controller, :authorize => true)
    expect(resource.send(:resource_class)).to eq(Admin::Dashboard)
  end

  it "should build a new resource with hash if params[:id] is not specified" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "should build a new resource for namespaced model with hash if params[:id] is not specified" do
    @params.merge!(:action => "create", 'sub_project' => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller, :class => ::Sub::Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "should build a new resource for namespaced controller and namespaced model with hash if params[:id] is not specified" do
    @params.merge!(:controller => "Admin::SubProjectsController", :action => "create", 'sub_project' => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller, :class => Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@sub_project).name).to eq("foobar")
  end

  it "should build a new resource with attributes from current ability" do
    @params.merge!(:action => "new")
    @ability.can(:create, Project, :name => "from conditions")
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("from conditions")
  end

  it "should override initial attributes with params" do
    @params.merge!(:action => "new", :project => {:name => "from params"})
    @ability.can(:create, Project, :name => "from conditions")
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("from params")
  end

  it "should build a collection when on index action when class responds to accessible_by" do
    allow(Project).to receive(:accessible_by).with(@ability, :index) { :found_projects }
    @params[:action] = "index"
    resource = CanCan::ControllerResource.new(@controller, :project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_get(:@projects)).to eq(:found_projects)
  end

  it "should not build a collection when on index action when class does not respond to accessible_by" do
    @params[:action] = "index"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_defined?(:@projects)).to be_false
  end

  it "should not use accessible_by when defining abilities through a block" do
    allow(Project).to receive(:accessible_by).with(@ability) { :found_projects }
    @params[:action] = "index"
    @ability.can(:read, Project) { |p| false }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_defined?(:@projects)).to be_false
  end

  it "should not authorize single resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@project, :some_project)
    allow(@controller).to receive(:authorize!).with(:index, Project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should authorize parent resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@category, :some_category)
    allow(@controller).to receive(:authorize!).with(:show, :some_category) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :category, :parent => true)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should perform authorization using controller action and loaded model" do
    @params.merge!(:action => "show", :id => "123")
    @controller.instance_variable_set(:@project, :some_project)
    allow(@controller).to receive(:authorize!).with(:show, :some_project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should perform authorization using controller action and non loaded model" do
    @params.merge!(:action => "show", :id => "123")
    allow(@controller).to receive(:authorize!).with(:show, Project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should call load_resource and authorize_resource for load_and_authorize_resource" do
    @params.merge!(:action => "show", :id => "123")
    resource = CanCan::ControllerResource.new(@controller)
    expect(resource).to receive(:load_resource)
    expect(resource).to receive(:authorize_resource)
    resource.load_and_authorize_resource
  end

  it "should not build a single resource when on custom collection action even with id" do
    @params.merge!(:action => "sort", :id => "123")
    resource = CanCan::ControllerResource.new(@controller, :collection => [:sort, :list])
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end

  it "should load a collection resource when on custom action with no id param" do
    allow(Project).to receive(:accessible_by).with(@ability, :sort) { :found_projects }
    @params[:action] = "sort"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_get(:@projects)).to eq(:found_projects)
  end

  it "should build a resource when on custom new action even when params[:id] exists" do
    @params.merge!(:action => "build", :id => "123")
    allow(Project).to receive(:new) { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :new => :build)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should not try to load resource for other action if params[:id] is undefined" do
    @params[:action] = "list"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end

  it "should be a parent resource when name is provided which doesn't match controller" do
    resource = CanCan::ControllerResource.new(@controller, :category)
    expect(resource).to be_parent
  end

  it "should not be a parent resource when name is provided which matches controller" do
    resource = CanCan::ControllerResource.new(@controller, :project)
    expect(resource).to_not be_parent
  end

  it "should be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :project, {:parent => true})
    expect(resource).to be_parent
  end

  it "should not be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :category, {:parent => false})
    expect(resource).to_not be_parent
  end

  it "should have the specified resource_class if 'name' is passed to load_resource" do
    class Section
    end

    resource = CanCan::ControllerResource.new(@controller, :section)
    expect(resource.send(:resource_class)).to eq(Section)
  end

  it "should load parent resource through proper id parameter" do
    project = Project.create!
    @params.merge!(:controller => "categories", :action => "index", :project_id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should load resource through the association of another parent resource using instance variable" do
    @params.merge!(:action => "show", :id => "123")
    category = double(projects: {})
    @controller.instance_variable_set(:@category, category)
    allow(category.projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should load resource through the custom association name" do
    @params.merge!(:action => "show", :id => "123")
    category = double(custom_projects: {})
    @controller.instance_variable_set(:@category, category)
    allow(category.custom_projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :through_association => :custom_projects)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should load resource through the association of another parent resource using method" do
    @params.merge!(:action => "show", :id => "123")
    category = double(projects: {})
    allow(@controller).to receive(:category) { category }
    allow(category.projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should not load through parent resource if instance isn't loaded when shallow" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :shallow => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should raise AccessDenied when attempting to load resource through nil" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    expect {
      resource.load_resource
    }.to raise_error(CanCan::AccessDenied) { |exception|
      expect(exception.action).to eq(:show)
      expect(exception.subject).to eq(Project)
    }
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end

  it "should authorize nested resource through parent association on index action" do
    @params.merge!(:action => "index")
    @controller.instance_variable_set(:@category, category = double)
    allow(@controller).to receive(:authorize!).with(:index, category => Project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should load through first matching if multiple are given" do
    @params.merge!(:action => "show", :id => "123")
    category = double(projects: {})
    @controller.instance_variable_set(:@category, category)
    allow(category.projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => [:category, :user])
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should find record through has_one association with :singleton option without id param" do
    @params.merge!(:action => "show", :id => nil)
    category = double(project: :some_project)
    @controller.instance_variable_set(:@category, category)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "should not build record through has_one association with :singleton option because it can cause it to delete it in the database" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    category = Category.new
    @controller.instance_variable_set(:@category, category)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
    expect(@controller.instance_variable_get(:@project).category).to eq(category)
  end

  it "should find record through has_one association with :singleton and :shallow options" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true, :shallow => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should build record through has_one association with :singleton and :shallow options" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true, :shallow => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "should only authorize :show action on parent resource" do
    project = Project.create!
    @params.merge!(:action => "new", :project_id => project.id)
    allow(@controller).to receive(:authorize!).with(:show, project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :project, :parent => true)
    expect { resource.load_and_authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should load the model using a custom class" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :class => Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should load the model using a custom namespaced class" do
    project = Sub::Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :class => ::Sub::Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should authorize based on resource name if class is false" do
    @params.merge!(:action => "show", :id => "123")
    allow(@controller).to receive(:authorize!).with(:show, :project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :class => false)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "should load and authorize using custom instance name" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    allow(@controller).to receive(:authorize!).with(:show, project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :instance_name => :custom_project)
    expect { resource.load_and_authorize_resource }.to raise_error(CanCan::AccessDenied)
    expect(@controller.instance_variable_get(:@custom_project)).to eq(project)
  end

  it "should load resource using custom ID param" do
    project = Project.create!
    @params.merge!(:action => "show", :the_project => project.id)
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  # CVE-2012-5664
  it "should always convert id param to string" do
    @params.merge!(:action => "show", :the_project => { :malicious => "I am" })
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project)
    expect(resource.send(:id_param).class).to eq(String)
  end

  it "should load resource using custom find_by attribute" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    resource = CanCan::ControllerResource.new(@controller, :find_by => :name)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should allow full find method to be passed into find_by option" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    resource = CanCan::ControllerResource.new(@controller, :find_by => :find_by_name)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "should raise ImplementationRemoved when adding :name option" do
    expect {
      CanCan::ControllerResource.new(@controller, :name => :foo)
    }.to raise_error(CanCan::ImplementationRemoved)
  end

  it "should raise ImplementationRemoved exception when specifying :resource option since it is no longer used" do
    expect {
      CanCan::ControllerResource.new(@controller, :resource => Project)
    }.to raise_error(CanCan::ImplementationRemoved)
  end

  it "should raise ImplementationRemoved exception when passing :nested option" do
    expect {
      CanCan::ControllerResource.new(@controller, :nested => :project)
    }.to raise_error(CanCan::ImplementationRemoved)
  end

  it "should skip resource behavior for :only actions in array" do
    allow(@controller_class).to receive(:cancan_skipper) { {:load => {nil => {:only => [:index, :show]}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_true
    expect(CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load)).to be_false
    @params.merge!(:action => "show")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_true
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_false
  end

  it "should skip resource behavior for :only one action on resource" do
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {:project => {:only => :index}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller).skip?(:authorize)).to be_false
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_true
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_false
  end

  it "should skip resource behavior :except actions in array" do
    allow(@controller_class).to receive(:cancan_skipper) { {:load => {nil => {:except => [:index, :show]}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_false
    @params.merge!(:action => "show")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_false
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_true
    expect(CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load)).to be_false
  end

  it "should skip resource behavior :except one action on resource" do
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {:project => {:except => :index}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_false
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller).skip?(:authorize)).to be_false
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_true
  end

  it "should skip loading and authorization" do
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {nil => {}}, :load => {nil => {}}} }
    @params.merge!(:action => "new")
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.load_and_authorize_resource }.not_to raise_error
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end
end
