require "spec_helper"

describe CanCan::ControllerAdditions do
  before(:each) do
    @params = HashWithIndifferentAccess.new
    @controller_class = Class.new
    @controller = @controller_class.new
    @controller.stub(:params) { @params }
    @controller.stub(:current_user) { :current_user }
    @controller_class.should_receive(:helper_method).with(:can?, :cannot?, :current_ability)
    @controller_class.send(:include, CanCan::ControllerAdditions)
  end

  it "raises ImplementationRemoved when attempting to call load/authorize/skip/check calls on a controller" do
    lambda { @controller_class.load_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.authorize_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.skip_load_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.skip_authorize_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.check_authorization }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.skip_authorization_check }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.cancan_skipper }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "authorize! should pass args to current ability" do
    @controller.current_ability.should_receive(:authorize!).with(:foo, :bar)
    @controller.authorize!(:foo, :bar)
  end

  it "provides a can? and cannot? methods which go through the current ability" do
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
    @controller.cannot?(:foo, :bar).should be_true
  end

  it "load_and_authorize_resource adds a before filter which passes call to ControllerResource" do
    controller_resource = double("controller_resource")
    controller_resource.should_receive(:process)
    CanCan::ControllerResource.stub(:new).with(@controller, nil, :load => true, :authorize => true, :foo => :bar) { controller_resource }
    @controller_class.should_receive(:before_filter).with({}).and_yield(@controller)
    @controller_class.load_and_authorize_resource :foo => :bar
  end

  it "load_and_authorize_resource passes first argument as the resource name" do
    controller_resource = double("controller_resource")
    controller_resource.should_receive(:process)
    CanCan::ControllerResource.stub(:new).with(@controller, :project, :load => true, :authorize => true, :foo => :bar) { controller_resource }
    @controller_class.should_receive(:before_filter).with({}).and_yield(@controller)
    @controller_class.load_and_authorize_resource :project, :foo => :bar
  end

  it "load_and_authorize_resource passes :only, :except, :if, :unless options to before filter" do
    controller_resource = double("controller_resource")
    controller_resource.should_receive(:process)
    CanCan::ControllerResource.stub(:new).with(@controller, nil, :load => true, :authorize => true) { controller_resource }
    @controller_class.should_receive(:before_filter).with(:only => 1, :except => 2, :if => 3, :unless => 4).and_yield(@controller)
    @controller_class.load_and_authorize_resource :only => 1, :except => 2, :if => 3, :unless => 4
  end

  it "load_and_authorize_resource with :prepend prepends the before filter" do
    @controller_class.should_receive(:prepend_before_filter).with({})
    @controller_class.load_and_authorize_resource :foo => :bar, :prepend => true
  end

  it "cancan_resource_class should be ControllerResource by default" do
    @controller.class.cancan_resource_class.should == CanCan::ControllerResource
  end

  it "cancan_resource_class should be InheritedResource when class includes InheritedResources::Actions" do
    @controller.class.stub(:ancestors) { ["InheritedResources::Actions"] }
    @controller.class.cancan_resource_class.should == CanCan::InheritedResource
  end

  it "enable_authorization should call authorize! with controller and action name" do
    @params.merge!(:controller => "projects", :action => "create")
    @controller.should_receive(:authorize!).with("create", "projects")
    @controller_class.stub(:before_filter).with(:only => :foo, :except => :bar).and_yield(@controller)
    @controller_class.stub(:after_filter).with(:only => :foo, :except => :bar)
    @controller_class.enable_authorization(:only => :foo, :except => :bar)
  end

  it "enable_authorization should raise InsufficientAuthorizationCheck when not fully authoried" do
    @params.merge!(:controller => "projects", :action => "create")
    @controller_class.stub(:before_filter).with(:only => :foo, :except => :bar)
    @controller_class.stub(:after_filter).with(:only => :foo, :except => :bar).and_yield(@controller)
    lambda {
      @controller_class.enable_authorization(:only => :foo, :except => :bar)
    }.should raise_error(CanCan::InsufficientAuthorizationCheck)
  end

  it "enable_authorization should not call authorize! when :if is false" do
    @authorize_called = false
    @controller.stub(:authorize?) { false }
    @controller.stub(:authorize!) { @authorize_called = true }
    @controller_class.should_receive(:before_filter).with({}).and_yield(@controller)
    @controller_class.should_receive(:after_filter).with({}).and_yield(@controller)
    @controller_class.enable_authorization(:if => :authorize?)
    @authorize_called.should be_false
  end

  it "enable_authorization should not call authorize! when :unless is true" do
    @authorize_called = false
    @controller.stub(:engine_controller?) { true }
    @controller.stub(:authorize!) { @authorize_called = true }
    @controller_class.should_receive(:before_filter).with({}).and_yield(@controller)
    @controller_class.should_receive(:after_filter).with({}).and_yield(@controller)
    @controller_class.enable_authorization(:unless => :engine_controller?)
    @authorize_called.should be_false
  end

  it "enable_authorization should pass block to rescue_from CanCan::Unauthorized call" do
    @block_called = false
    @controller_class.should_receive(:before_filter).with({})
    @controller_class.should_receive(:after_filter).with({})
    @controller_class.should_receive(:rescue_from).with(CanCan::Unauthorized).and_yield(:exception)
    @controller_class.enable_authorization { |e| @block_called = (e == :exception) }
    @block_called.should be_true
  end
end
