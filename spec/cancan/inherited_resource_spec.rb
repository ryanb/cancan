require "spec_helper"

describe CanCan::InheritedResource do
  before(:each) do
    @params = HashWithIndifferentAccess.new(:controller => "projects")
    @controller_class = Class.new
    @controller = @controller_class.new
    @ability = Ability.new(nil)
    @controller.stub(:params).and_return(@params)
    @controller.stub(:current_ability).and_return(@ability)
    @controller_class.stub(:cancan_skipper).and_return({:authorize => {}, :load => {}})
  end

  it "show should load resource through @controller.resource" do
    @params.merge!(:action => "show", :id => 123)
    @controller.stub(:resource).and_return(:project_resource)
    CanCan::InheritedResource.new(@controller).load_resource
    @controller.instance_variable_get(:@project).should == :project_resource
  end

  it "new should load through @controller.build_resource" do
    @params[:action] = "new"
    @controller.stub(:build_resource).and_return(:project_resource)
    CanCan::InheritedResource.new(@controller).load_resource
    @controller.instance_variable_get(:@project).should == :project_resource
  end

  it "index should load through @controller.association_chain when parent" do
    @params[:action] = "index"
    @controller.stub(:association_chain).and_return(@controller.instance_variable_set(:@project, :project_resource))
    CanCan::InheritedResource.new(@controller, :parent => true).load_resource
    @controller.instance_variable_get(:@project).should == :project_resource
  end

  it "index should load through @controller.end_of_association_chain" do
    @params[:action] = "index"
    Project.stub(:accessible_by).with(@ability, :index).and_return(:projects)
    @controller.stub(:end_of_association_chain).and_return(Project)
    CanCan::InheritedResource.new(@controller).load_resource
    @controller.instance_variable_get(:@projects).should == :projects
  end

  it "should build a new resource with attributes from current ability" do
    @params[:action] = "new"
    @ability.can(:create, Project, :name => "from conditions")
    @controller.stub(:build_resource).and_return(Struct.new(:name).new)
    resource = CanCan::InheritedResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@project).name.should == "from conditions"
  end

  it "should override initial attributes with params" do
    @params.merge!(:action => "new", :project => {:name => "from params"})
    @ability.can(:create, Project, :name => "from conditions")
    @controller.stub(:build_resource).and_return(Struct.new(:name).new)
    resource = CanCan::ControllerResource.new(@controller)
    resource.load_resource
    @controller.instance_variable_get(:@project).name.should == "from params"
  end
end
