require "spec_helper"

describe CanCan::ControllerAdditions do
  before(:each) do
    @controller_class = Class.new
    @controller = @controller_class.new
    stub(@controller).params { {} }
    stub(@controller).current_user { :current_user }
    mock(@controller_class).helper_method(:can?, :cannot?, :current_ability)
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

  it "load_and_authorize_resource with :prepend should prepend the before filter" do
    mock(@controller_class).prepend_before_filter({})
    @controller_class.load_and_authorize_resource :foo => :bar, :prepend => true
  end

  it "authorize_resource should setup a before filter which passes call to ControllerResource" do
    stub(CanCan::ControllerResource).new(@controller, nil, :foo => :bar).mock!.authorize_resource
    mock(@controller_class).before_filter(:except => :show, :if => true) { |options, block| block.call(@controller) }
    @controller_class.authorize_resource :foo => :bar, :except => :show, :if => true
  end

  it "load_resource should setup a before filter which passes call to ControllerResource" do
    stub(CanCan::ControllerResource).new(@controller, nil, :foo => :bar).mock!.load_resource
    mock(@controller_class).before_filter(:only => [:show, :index], :unless => false) { |options, block| block.call(@controller) }
    @controller_class.load_resource :foo => :bar, :only => [:show, :index], :unless => false
  end

  it "skip_authorization_check should set up a before filter which sets @_authorized to true" do
    mock(@controller_class).before_filter(:filter_options) { |options, block| block.call(@controller) }
    @controller_class.skip_authorization_check(:filter_options)
    @controller.instance_variable_get(:@_authorized).should be_true
  end

  it "check_authorization should trigger AuthorizationNotPerformed in after filter" do
    mock(@controller_class).after_filter(:only => [:test]) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.check_authorization(:only => [:test])
    }.should raise_error(CanCan::AuthorizationNotPerformed)
  end

  it "check_authorization should not trigger AuthorizationNotPerformed when :if is false" do
    stub(@controller).check_auth? { false }
    mock(@controller_class).after_filter({}) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.check_authorization(:if => :check_auth?)
    }.should_not raise_error(CanCan::AuthorizationNotPerformed)
  end

  it "check_authorization should not trigger AuthorizationNotPerformed when :unless is true" do
    stub(@controller).engine_controller? { true }
    mock(@controller_class).after_filter({}) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.check_authorization(:unless => :engine_controller?)
    }.should_not raise_error(CanCan::AuthorizationNotPerformed)
  end

  it "check_authorization should not raise error when @_authorized is set" do
    @controller.instance_variable_set(:@_authorized, true)
    mock(@controller_class).after_filter(:only => [:test]) { |options, block| block.call(@controller) }
    lambda {
      @controller_class.check_authorization(:only => [:test])
    }.should_not raise_error(CanCan::AuthorizationNotPerformed)
  end

  it "cancan_resource_class should be ControllerResource by default" do
    @controller.class.cancan_resource_class.should == CanCan::ControllerResource
  end

  it "cancan_resource_class should be InheritedResource when class includes InheritedResources::Actions" do
    stub(@controller.class).ancestors { ["InheritedResources::Actions"] }
    @controller.class.cancan_resource_class.should == CanCan::InheritedResource
  end

  it "cancan_skipper should be an empty hash with :authorize and :load options and remember changes" do
    @controller_class.cancan_skipper.should == {:authorize => {}, :load => {}}
    @controller_class.cancan_skipper[:load] = true
    @controller_class.cancan_skipper[:load].should == true
  end

  it "skip_authorize_resource should add itself to the cancan skipper with given model name and options" do
    @controller_class.skip_authorize_resource(:project, :only => [:index, :show])
    @controller_class.cancan_skipper[:authorize][:project].should == {:only => [:index, :show]}
    @controller_class.skip_authorize_resource(:only => [:index, :show])
    @controller_class.cancan_skipper[:authorize][nil].should == {:only => [:index, :show]}
    @controller_class.skip_authorize_resource(:article)
    @controller_class.cancan_skipper[:authorize][:article].should == {}
  end

  it "skip_load_resource should add itself to the cancan skipper with given model name and options" do
    @controller_class.skip_load_resource(:project, :only => [:index, :show])
    @controller_class.cancan_skipper[:load][:project].should == {:only => [:index, :show]}
    @controller_class.skip_load_resource(:only => [:index, :show])
    @controller_class.cancan_skipper[:load][nil].should == {:only => [:index, :show]}
    @controller_class.skip_load_resource(:article)
    @controller_class.cancan_skipper[:load][:article].should == {}
  end

  it "skip_load_and_authore_resource should add itself to the cancan skipper with given model name and options" do
    @controller_class.skip_load_and_authorize_resource(:project, :only => [:index, :show])
    @controller_class.cancan_skipper[:load][:project].should == {:only => [:index, :show]}
    @controller_class.cancan_skipper[:authorize][:project].should == {:only => [:index, :show]}
  end
end
