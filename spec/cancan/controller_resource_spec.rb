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

  it "loads the resource into an instance variable if params[:id] is specified" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "does not load resource into an instance variable if already set" do
    @params.merge!(:action => "show", :id => "123")
    @controller.instance_variable_set(:@project, :some_project)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "loads resource for namespaced controller" do
    project = Project.create!
    @params.merge!(:controller => "admin/projects", :action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "attempts to load a resource with the same namespace as the controller when using :: for namespace" do
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
  it "creates through the namespaced params" do
    module MyEngine
      class Project < ::Project; end
    end

    @params.merge!(:controller => "MyEngine::ProjectsController", :action => "create", :my_engine_project => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "loads resource for namespaced controller when using '::' for namespace" do
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

  it "builds a new resource with hash if params[:id] is not specified" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "builds a new resource for namespaced model with hash if params[:id] is not specified" do
    @params.merge!(:action => "create", 'sub_project' => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller, :class => ::Sub::Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "builds a new resource for namespaced controller and namespaced model with hash if params[:id] is not specified" do
    @params.merge!(:controller => "Admin::SubProjectsController", :action => "create", 'sub_project' => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller, :class => Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@sub_project).name).to eq("foobar")
  end

  it "builds a new resource with attributes from current ability" do
    @params.merge!(:action => "new")
    @ability.can(:create, Project, :name => "from conditions")
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("from conditions")
  end

  it "overrides initial attributes with params" do
    @params.merge!(:action => "new", :project => {:name => "from params"})
    @ability.can(:create, Project, :name => "from conditions")
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("from params")
  end

  it "builds a collection when on index action when class responds to accessible_by" do
    allow(Project).to receive(:accessible_by).with(@ability, :index) { :found_projects }
    @params[:action] = "index"
    resource = CanCan::ControllerResource.new(@controller, :project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_get(:@projects)).to eq(:found_projects)
  end

  it "does not build a collection when on index action when class does not respond to accessible_by" do
    @params[:action] = "index"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_defined?(:@projects)).to be_false
  end

  it "does not use accessible_by when defining abilities through a block" do
    allow(Project).to receive(:accessible_by).with(@ability) { :found_projects }
    @params[:action] = "index"
    @ability.can(:read, Project) { |p| false }
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_defined?(:@projects)).to be_false
  end

  it "does not authorize single resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@project, :some_project)
    allow(@controller).to receive(:authorize!).with(:index, Project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "authorizes parent resource in collection action" do
    @params[:action] = "index"
    @controller.instance_variable_set(:@category, :some_category)
    allow(@controller).to receive(:authorize!).with(:show, :some_category) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :category, :parent => true)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "performs authorization using controller action and loaded model" do
    @params.merge!(:action => "show", :id => "123")
    @controller.instance_variable_set(:@project, :some_project)
    allow(@controller).to receive(:authorize!).with(:show, :some_project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "performs authorization using controller action and non loaded model" do
    @params.merge!(:action => "show", :id => "123")
    allow(@controller).to receive(:authorize!).with(:show, Project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "calls load_resource and authorize_resource for load_and_authorize_resource" do
    @params.merge!(:action => "show", :id => "123")
    resource = CanCan::ControllerResource.new(@controller)
    expect(resource).to receive(:load_resource)
    expect(resource).to receive(:authorize_resource)
    resource.load_and_authorize_resource
  end

  it "does not build a single resource when on custom collection action even with id" do
    @params.merge!(:action => "sort", :id => "123")
    resource = CanCan::ControllerResource.new(@controller, :collection => [:sort, :list])
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end

  it "loads a collection resource when on custom action with no id param" do
    allow(Project).to receive(:accessible_by).with(@ability, :sort) { :found_projects }
    @params[:action] = "sort"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
    expect(@controller.instance_variable_get(:@projects)).to eq(:found_projects)
  end

  it "builds a resource when on custom new action even when params[:id] exists" do
    @params.merge!(:action => "build", :id => "123")
    allow(Project).to receive(:new) { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :new => :build)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "does not try to load resource for other action if params[:id] is undefined" do
    @params[:action] = "list"
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end

  it "is a parent resource when name is provided which doesn't match controller" do
    resource = CanCan::ControllerResource.new(@controller, :category)
    expect(resource).to be_parent
  end

  it "does not be a parent resource when name is provided which matches controller" do
    resource = CanCan::ControllerResource.new(@controller, :project)
    expect(resource).to_not be_parent
  end

  it "is parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :project, {:parent => true})
    expect(resource).to be_parent
  end

  it "does not be parent if specified in options" do
    resource = CanCan::ControllerResource.new(@controller, :category, {:parent => false})
    expect(resource).to_not be_parent
  end

  it "has the specified resource_class if 'name' is passed to load_resource" do
    class Section
    end

    resource = CanCan::ControllerResource.new(@controller, :section)
    expect(resource.send(:resource_class)).to eq(Section)
  end

  it "loads parent resource through proper id parameter" do
    project = Project.create!
    @params.merge!(:controller => "categories", :action => "index", :project_id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "loads resource through the association of another parent resource using instance variable" do
    @params.merge!(:action => "show", :id => "123")
    category = double(:projects => {})
    @controller.instance_variable_set(:@category, category)
    allow(category.projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "loads resource through the custom association name" do
    @params.merge!(:action => "show", :id => "123")
    category = double(:custom_projects => {})
    @controller.instance_variable_set(:@category, category)
    allow(category.custom_projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :through_association => :custom_projects)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "loads resource through the association of another parent resource using method" do
    @params.merge!(:action => "show", :id => "123")
    category = double(:projects => {})
    allow(@controller).to receive(:category) { category }
    allow(category.projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "does not load through parent resource if instance isn't loaded when shallow" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :shallow => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "raises AccessDenied when attempting to load resource through nil" do
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

  it "authorizes nested resource through parent association on index action" do
    @params.merge!(:action => "index")
    @controller.instance_variable_set(:@category, category = double)
    allow(@controller).to receive(:authorize!).with(:index, category => Project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :through => :category)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "loads through first matching if multiple are given" do
    @params.merge!(:action => "show", :id => "123")
    category = double(:projects => {})
    @controller.instance_variable_set(:@category, category)
    allow(category.projects).to receive(:find).with("123") { :some_project }
    resource = CanCan::ControllerResource.new(@controller, :through => [:category, :user])
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "finds record through has_one association with :singleton option without id param" do
    @params.merge!(:action => "show", :id => nil)
    category = double(:project => :some_project)
    @controller.instance_variable_set(:@category, category)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(:some_project)
  end

  it "does not build record through has_one association with :singleton option because it can cause it to delete it in the database" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    category = Category.new
    @controller.instance_variable_set(:@category, category)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
    expect(@controller.instance_variable_get(:@project).category).to eq(category)
  end

  it "finds record through has_one association with :singleton and :shallow options" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true, :shallow => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "builds record through has_one association with :singleton and :shallow options" do
    @params.merge!(:action => "create", :project => {:name => "foobar"})
    resource = CanCan::ControllerResource.new(@controller, :through => :category, :singleton => true, :shallow => true)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project).name).to eq("foobar")
  end

  it "only authorizes :show action on parent resource" do
    project = Project.create!
    @params.merge!(:action => "new", :project_id => project.id)
    allow(@controller).to receive(:authorize!).with(:show, project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :project, :parent => true)
    expect { resource.load_and_authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "loads the model using a custom class" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :class => Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "loads the model using a custom namespaced class" do
    project = Sub::Project.create!
    @params.merge!(:action => "show", :id => project.id)
    resource = CanCan::ControllerResource.new(@controller, :class => ::Sub::Project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "authorizes based on resource name if class is false" do
    @params.merge!(:action => "show", :id => "123")
    allow(@controller).to receive(:authorize!).with(:show, :project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :class => false)
    expect { resource.authorize_resource }.to raise_error(CanCan::AccessDenied)
  end

  it "loads and authorize using custom instance name" do
    project = Project.create!
    @params.merge!(:action => "show", :id => project.id)
    allow(@controller).to receive(:authorize!).with(:show, project) { raise CanCan::AccessDenied }
    resource = CanCan::ControllerResource.new(@controller, :instance_name => :custom_project)
    expect { resource.load_and_authorize_resource }.to raise_error(CanCan::AccessDenied)
    expect(@controller.instance_variable_get(:@custom_project)).to eq(project)
  end

  it "loads resource using custom ID param" do
    project = Project.create!
    @params.merge!(:action => "show", :the_project => project.id)
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  # CVE-2012-5664
  it "always converts id param to string" do
    @params.merge!(:action => "show", :the_project => { :malicious => "I am" })
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project)
    expect(resource.send(:id_param).class).to eq(String)
  end

  it "should id param return nil if param is nil" do
    @params.merge!(:action => "show", :the_project => nil)
    resource = CanCan::ControllerResource.new(@controller, :id_param => :the_project)
    expect(resource.send(:id_param)).to be_nil
  end

  it "loads resource using custom find_by attribute" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    resource = CanCan::ControllerResource.new(@controller, :find_by => :name)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "allows full find method to be passed into find_by option" do
    project = Project.create!(:name => "foo")
    @params.merge!(:action => "show", :id => "foo")
    resource = CanCan::ControllerResource.new(@controller, :find_by => :find_by_name)
    resource.load_resource
    expect(@controller.instance_variable_get(:@project)).to eq(project)
  end

  it "raises ImplementationRemoved when adding :name option" do
    expect {
      CanCan::ControllerResource.new(@controller, :name => :foo)
    }.to raise_error(CanCan::ImplementationRemoved)
  end

  it "raises ImplementationRemoved exception when specifying :resource option since it is no longer used" do
    expect {
      CanCan::ControllerResource.new(@controller, :resource => Project)
    }.to raise_error(CanCan::ImplementationRemoved)
  end

  it "raises ImplementationRemoved exception when passing :nested option" do
    expect {
      CanCan::ControllerResource.new(@controller, :nested => :project)
    }.to raise_error(CanCan::ImplementationRemoved)
  end

  it "skips resource behavior for :only actions in array" do
    allow(@controller_class).to receive(:cancan_skipper) { {:load => {nil => {:only => [:index, :show]}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_true
    expect(CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load)).to be_false
    @params.merge!(:action => "show")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_true
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_false
  end

  it "skips resource behavior for :only one action on resource" do
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {:project => {:only => :index}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller).skip?(:authorize)).to be_false
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_true
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_false
  end

  it "skips resource behavior :except actions in array" do
    allow(@controller_class).to receive(:cancan_skipper) { {:load => {nil => {:except => [:index, :show]}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_false
    @params.merge!(:action => "show")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_false
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller).skip?(:load)).to be_true
    expect(CanCan::ControllerResource.new(@controller, :some_resource).skip?(:load)).to be_false
  end

  it "skips resource behavior :except one action on resource" do
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {:project => {:except => :index}}} }
    @params.merge!(:action => "index")
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_false
    @params.merge!(:action => "other_action")
    expect(CanCan::ControllerResource.new(@controller).skip?(:authorize)).to be_false
    expect(CanCan::ControllerResource.new(@controller, :project).skip?(:authorize)).to be_true
  end

  it "skips loading and authorization" do
    allow(@controller_class).to receive(:cancan_skipper) { {:authorize => {nil => {}}, :load => {nil => {}}} }
    @params.merge!(:action => "new")
    resource = CanCan::ControllerResource.new(@controller)
    expect { resource.load_and_authorize_resource }.not_to raise_error
    expect(@controller.instance_variable_get(:@project)).to be_nil
  end

  context "with a strong parameters method" do

    it "only calls the santitize method with actions matching param_actions" do
      @params.merge!(:controller => "project", :action => "update")
      @controller.stub(:resource_params).and_return(:resource => 'params')
      resource = CanCan::ControllerResource.new(@controller)
      resource.stub(:param_actions => [:create])

      @controller.should_not_receive(:send).with(:resource_params)
      resource.send("resource_params")
    end

    it "uses the specified option for santitizing input" do
      @params.merge!(:controller => "project", :action => "create")
      @controller.stub(:resource_params).and_return(:resource => 'params')
      @controller.stub(:project_params).and_return(:model => 'params')
      @controller.stub(:create_params).and_return(:create => 'params')
      @controller.stub(:custom_params).and_return(:custom => 'params')
      resource = CanCan::ControllerResource.new(@controller, {:param_method => :custom_params})
      expect(resource.send("resource_params")).to eq(:custom => 'params')
    end

    it "prefers to use the create_params method for santitizing input" do
      @params.merge!(:controller => "project", :action => "create")
      @controller.stub(:resource_params).and_return(:resource => 'params')
      @controller.stub(:project_params).and_return(:model => 'params')
      @controller.stub(:create_params).and_return(:create => 'params')
      @controller.stub(:custom_params).and_return(:custom => 'params')
      resource = CanCan::ControllerResource.new(@controller)
      expect(resource.send("resource_params")).to eq(:create => 'params')
    end

    it "uses the proper action param based on the action" do
      @params.merge!(:controller => "project", :action => "update")
      @controller.stub(:create_params).and_return(:create => 'params')
      @controller.stub(:update_params).and_return(:update => 'params')
      resource = CanCan::ControllerResource.new(@controller)
      expect(resource.send("resource_params")).to eq(:update => 'params')
    end

    it "prefers to use the <model_name>_params method for santitizing input if create is not found" do
      @params.merge!(:controller => "project", :action => "create")
      @controller.stub(:resource_params).and_return(:resource => 'params')
      @controller.stub(:project_params).and_return(:model => 'params')
      @controller.stub(:custom_params).and_return(:custom => 'params')
      resource = CanCan::ControllerResource.new(@controller)
      expect(resource.send("resource_params")).to eq(:model => 'params')
    end

    it "prefers to use the resource_params method for santitizing input if create or model is not found" do
      @params.merge!(:controller => "project", :action => "create")
      @controller.stub(:resource_params).and_return(:resource => 'params')
      @controller.stub(:custom_params).and_return(:custom => 'params')
      resource = CanCan::ControllerResource.new(@controller)
      expect(resource.send("resource_params")).to eq(:resource => 'params')
    end
  end
end
