require "spec_helper"

describe CanCan::InheritedResource do
  before(:each) do
    @params = HashWithIndifferentAccess.new(:controller => "projects")
    @controller_class = Class.new
    @controller = @controller_class.new
    @ability = Ability.new(nil)
    stub(@controller).params { @params }
    stub(@controller).current_ability { @ability }
    stub(@controller_class).cancan_skipper { {:authorize => {}, :load => {}} }
  end

  it "show should load resource through @controller.resource" do
    @params.merge!(:action => "show", :id => 123)
    stub(@controller).resource { :project_resource }
    CanCan::InheritedResource.new(@controller).load_resource
    @controller.instance_variable_get(:@project).should == :project_resource
  end

  it "new should load through @controller.build_resource" do
    @params[:action] = "new"
    stub(@controller).build_resource { :project_resource }
    CanCan::InheritedResource.new(@controller).load_resource
    @controller.instance_variable_get(:@project).should == :project_resource
  end

  it "index should load through @controller.association_chain when parent" do
    @params[:action] = "index"
    stub(@controller).association_chain { @controller.instance_variable_set(:@project, :project_resource) }
    CanCan::InheritedResource.new(@controller, :parent => true).load_resource
    @controller.instance_variable_get(:@project).should == :project_resource
  end

  it "index should load through @controller.end_of_association_chain" do
    @params[:action] = "index"
    stub(Project).accessible_by(@ability, :index) { :projects }
    stub(@controller).end_of_association_chain { Project }
    CanCan::InheritedResource.new(@controller).load_resource
    @controller.instance_variable_get(:@projects).should == :projects
  end
end
