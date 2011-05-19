require "spec_helper"

describe CanCan::ControllerAdditions do
  before(:each) do
    @params = HashWithIndifferentAccess.new
    @controller_class = Class.new
    @controller = @controller_class.new
    stub(@controller).params { @params }
    stub(@controller).current_user { :current_user }
    mock(@controller_class).helper_method(:can?, :cannot?, :current_ability)
    @controller_class.send(:include, CanCan::ControllerAdditions)
  end

  it "should raise ImplementationRemoved when attempting to call load/authorize/skip/check calls on a controller" do
    lambda { @controller_class.load_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.authorize_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.skip_load_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.skip_authorize_resource }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.check_authorization }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.skip_authorization_check }.should raise_error(CanCan::ImplementationRemoved)
    lambda { @controller_class.cancan_skipper }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "authorize! should pass args to current ability" do
    mock(@controller.current_ability).authorize!(:foo, :bar)
    @controller.authorize!(:foo, :bar)
  end

  it "should provide a can? and cannot? methods which go through the current ability" do
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
    @controller.cannot?(:foo, :bar).should be_true
  end

  it "load_and_authorize_resource should setup a before filter which passes call to ControllerResource" do
    stub(CanCan::ControllerResource).new(@controller, nil, :load => true, :authorize => true, :foo => :bar).mock!.process
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    @controller_class.load_and_authorize_resource :foo => :bar
  end

  it "load_and_authorize_resource should properly pass first argument as the resource name" do
    stub(CanCan::ControllerResource).new(@controller, :project, :load => true, :authorize => true, :foo => :bar).mock!.process
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    @controller_class.load_and_authorize_resource :project, :foo => :bar
  end

  it "load_and_authorize_resource with :prepend should prepend the before filter" do
    mock(@controller_class).prepend_before_filter({})
    @controller_class.load_and_authorize_resource :foo => :bar, :prepend => true
  end

  it "cancan_resource_class should be ControllerResource by default" do
    @controller.class.cancan_resource_class.should == CanCan::ControllerResource
  end

  it "cancan_resource_class should be InheritedResource when class includes InheritedResources::Actions" do
    stub(@controller.class).ancestors { ["InheritedResources::Actions"] }
    @controller.class.cancan_resource_class.should == CanCan::InheritedResource
  end

  it "enable_authorization should call authorize! with controller and action name" do
    @params.merge!(:controller => "projects", :action => "create")
    mock(@controller).authorize!("create", "projects")
    stub(@controller_class).before_filter(:only => :foo, :except => :bar) { |options, block| block.call(@controller) }
    stub(@controller_class).after_filter(:only => :foo, :except => :bar)
    @controller_class.enable_authorization(:only => :foo, :except => :bar)
  end

  it "enable_authorization should raise InsufficientAuthorizationCheck when not fully authoried" do
    @params.merge!(:controller => "projects", :action => "create")
    stub(@ability).fully_authorized? { false }
    stub(@controller_class).before_filter(:only => :foo, :except => :bar)
    stub(@controller_class).after_filter(:only => :foo, :except => :bar) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.enable_authorization(:only => :foo, :except => :bar)
    }.should raise_error(CanCan::InsufficientAuthorizationCheck)
  end

  it "enable_authorization should not call authorize! when :if is false" do
    @authorize_called = false
    stub(@controller).authorize? { false }
    stub(@controller).authorize! { @authorize_called = true }
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    mock(@controller_class).after_filter({}) { |options, block| block.call(@controller) }
    @controller_class.enable_authorization(:if => :authorize?)
    @authorize_called.should be_false
  end

  it "enable_authorization should not call authorize! when :unless is true" do
    @authorize_called = false
    stub(@controller).engine_controller? { true }
    stub(@controller).authorize! { @authorize_called = true }
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    mock(@controller_class).after_filter({}) { |options, block| block.call(@controller) }
    @controller_class.enable_authorization(:unless => :engine_controller?)
    @authorize_called.should be_false
  end

  it "enable_authorization should pass block to rescue_from CanCan::Unauthorized call" do
    @block_called = false
    mock(@controller_class).before_filter({})
    mock(@controller_class).after_filter({})
    mock(@controller_class).rescue_from(CanCan::Unauthorized) { |options, block| block.call(:exception) }
    @controller_class.enable_authorization { |e| @block_called = (e == :exception) }
    @block_called.should be_true
  end
end
