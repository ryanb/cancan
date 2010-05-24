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

  it "should raise access denied exception if ability us unauthorized to perform a certain action" do
    begin
      @controller.authorize! :read, :foo, 1, 2, 3, :message => "Access denied!"
    rescue CanCan::AccessDenied => e
      e.message.should == "Access denied!"
      e.action.should == :read
      e.subject.should == :foo
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "should not raise access denied exception if ability is authorized to perform an action" do
    @controller.current_ability.can :read, :foo
    lambda { @controller.authorize!(:read, :foo) }.should_not raise_error
  end

  it "should raise access denied exception with default message if not specified" do
    begin
      @controller.authorize! :read, :foo
    rescue CanCan::AccessDenied => e
      e.default_message = "Access denied!"
      e.message.should == "Access denied!"
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "should have a current_ability method which generates an ability for the current user" do
    @controller.current_ability.should be_kind_of(Ability)
  end

  it "should provide a can? and cannot? methods which go through the current ability" do
    @controller.current_ability.should be_kind_of(Ability)
    @controller.can?(:foo, :bar).should be_false
    @controller.cannot?(:foo, :bar).should be_true
  end

  it "load_and_authorize_resource should setup a before filter which passes call to ResourceAuthorization" do
    stub(CanCan::ResourceAuthorization).new(@controller, @controller.params, :foo => :bar).mock!.load_and_authorize_resource
    mock(@controller_class).before_filter({}) { |options, block| block.call(@controller) }
    @controller_class.load_and_authorize_resource :foo => :bar
  end

  it "authorize_resource should setup a before filter which passes call to ResourceAuthorization" do
    stub(CanCan::ResourceAuthorization).new(@controller, @controller.params, :foo => :bar).mock!.authorize_resource
    mock(@controller_class).before_filter(:except => :show) { |options, block| block.call(@controller) }
    @controller_class.authorize_resource :foo => :bar, :except => :show
  end

  it "load_resource should setup a before filter which passes call to ResourceAuthorization" do
    stub(CanCan::ResourceAuthorization).new(@controller, @controller.params, :foo => :bar).mock!.load_resource
    mock(@controller_class).before_filter(:only => [:show, :index]) { |options, block| block.call(@controller) }
    @controller_class.load_resource :foo => :bar, :only => [:show, :index]
  end
end
