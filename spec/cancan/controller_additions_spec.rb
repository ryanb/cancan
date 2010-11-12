require "spec_helper"

describe CanCan::ControllerAdditions do
  before(:each) do
    @controller_class = Class.new
    @controller = @controller_class.new
    stub(@controller).params { {} }
    stub(@controller).current_user { :current_user }
    mock(@controller_class).helper_method(:can?, :cannot?)
    @controller_class.send(:include, CanCan::ControllerAdditions)
  end

  it "should raise ImplementationRemoved when attempting to call 'unauthorized!' on a controller" do
    lambda { @controller.unauthorized! }.should raise_error(CanCan::ImplementationRemoved)
  end

  it "authorize! should assign @_authorized instance variable and pass args to current ability" do
    mock(@controller.current_ability).authorize!(:foo, :bar)
    @controller.authorize!(:foo, :bar)
    @controller.instance_variable_get(:@_authorized).should be_true
  end

  it "should have a current_ability method which generates an ability for the current user" do
    @controller.current_ability.should be_kind_of(Ability)
  end

  it "should provide a can? and cannot? methods which go through the current ability" do
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
    @controller.cannot?(:foo, :bar).should be_true
  end

  it "load_and_authorize_resource should setup a before filter which passes call to ControllerResource" do
    stub(CanCan::ControllerResource).new(@controller, nil, :foo => :bar).mock!.load_and_authorize_resource
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    @controller_class.load_and_authorize_resource :foo => :bar
  end

  it "load_and_authorize_resource should properly pass first argument as the resource name" do
    stub(CanCan::ControllerResource).new(@controller, :project, :foo => :bar).mock!.load_and_authorize_resource
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    @controller_class.load_and_authorize_resource :project, :foo => :bar
  end

  it "authorize_resource should setup a before filter which passes call to ControllerResource" do
    stub(CanCan::ControllerResource).new(@controller, nil, :foo => :bar).mock!.authorize_resource
    mock(@controller_class).before_filter(:except => :show) { |options, block| block.call(@controller) }
    @controller_class.authorize_resource :foo => :bar, :except => :show
  end

  it "load_resource should setup a before filter which passes call to ControllerResource" do
    stub(CanCan::ControllerResource).new(@controller, nil, :foo => :bar).mock!.load_resource
    mock(@controller_class).before_filter(:only => [:show, :index]) { |options, block| block.call(@controller) }
    @controller_class.load_resource :foo => :bar, :only => [:show, :index]
  end

  it "skip_authorization_check should set up a before filter which sets @_authorized to true" do
    mock(@controller_class).before_filter(:filter_options) { |options, block| block.call(@controller) }
    @controller_class.skip_authorization_check(:filter_options)
    @controller.instance_variable_get(:@_authorized).should be_true
  end

  it "check_authorization should trigger AuthorizationNotPerformed in after filter" do
    mock(@controller_class).after_filter(:some_options) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.check_authorization(:some_options)
    }.should raise_error(CanCan::AuthorizationNotPerformed)
  end

  it "check_authorization should not raise error when @_authorized is set" do
    @controller.instance_variable_set(:@_authorized, true)
    mock(@controller_class).after_filter(:some_options) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.check_authorization(:some_options)
    }.should_not raise_error(CanCan::AuthorizationNotPerformed)
  end

  it "cancan_resource_class should be ControllerResource by default" do
    @controller.class.cancan_resource_class.should == CanCan::ControllerResource
  end

  it "cancan_resource_class should be InheritedResource when class includes InheritedResources::Actions" do
    stub(@controller.class).ancestors { ["InheritedResources::Actions"] }
    @controller.class.cancan_resource_class.should == CanCan::InheritedResource
  end
end
