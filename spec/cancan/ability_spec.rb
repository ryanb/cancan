require "spec_helper"

describe CanCan::Ability do
  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should be able to :read anything" do
    @ability.can :read, :all
    @ability.can?(:read, String).should be_true
    @ability.can?(:read, 123).should be_true
  end

  it "should not have permission to do something it doesn't know about" do
    @ability.can?(:foodfight, String).should be_false
  end

  it "should pass true to `can?` when non false/nil is returned in block" do
    @ability.can :read, :all
    @ability.can :read, Symbol do |sym|
      "foo" # TODO test that sym is nil when no instance is passed
    end
    @ability.can?(:read, :some_symbol).should == true
  end

  it "should pass nil to a block when no instance is passed" do
    @ability.can :read, Symbol do |sym|
      sym.should be_nil
      true
    end
    @ability.can?(:read, Symbol).should be_true
  end

  it "should pass to previous rule, if block returns false or nil" do
    @ability.can :read, Symbol
    @ability.can :read, Integer do |i|
      i < 5
    end
    @ability.can :read, Integer do |i|
      i > 10
    end
    @ability.can?(:read, Symbol).should be_true
    @ability.can?(:read, 11).should be_true
    @ability.can?(:read, 1).should be_true
    @ability.can?(:read, 6).should be_false
  end

  it "should not pass class with object if :all objects are accepted" do
    @ability.can :preview, :all do |object|
      object.should == 123
      @block_called = true
    end
    @ability.can?(:preview, 123)
    @block_called.should be_true
  end

  it "should not call block when only class is passed, only return true" do
    @block_called = false
    @ability.can :preview, :all do |object|
      @block_called = true
    end
    @ability.can?(:preview, Hash).should be_true
    @block_called.should be_false
  end

  it "should pass only object for global manage actions" do
    @ability.can :manage, String do |object|
      object.should == "foo"
      @block_called = true
    end
    @ability.can?(:stuff, "foo").should
    @block_called.should be_true
  end

  it "should alias update or destroy actions to modify action" do
    @ability.alias_action :update, :destroy, :to => :modify
    @ability.can :modify, :all
    @ability.can?(:update, 123).should be_true
    @ability.can?(:destroy, 123).should be_true
  end

  it "should allow deeply nested aliased actions" do
    @ability.alias_action :increment, :to => :sort
    @ability.alias_action :sort, :to => :modify
    @ability.can :modify, :all
    @ability.can?(:increment, 123).should be_true
  end

  it "should always call block with arguments when passing no arguments to can" do
    @ability.can do |action, object_class, object|
      action.should == :foo
      object_class.should == 123.class
      object.should == 123
      @block_called = true
    end
    @ability.can?(:foo, 123)
    @block_called.should be_true
  end

  it "should pass nil to object when comparing class with can check" do
    @ability.can do |action, object_class, object|
      action.should == :foo
      object_class.should == Hash
      object.should be_nil
      @block_called = true
    end
    @ability.can?(:foo, Hash)
    @block_called.should be_true
  end

  it "should automatically alias index and show into read calls" do
    @ability.can :read, :all
    @ability.can?(:index, 123).should be_true
    @ability.can?(:show, 123).should be_true
  end

  it "should automatically alias new and edit into create and update respectively" do
    @ability.can :create, :all
    @ability.can :update, :all
    @ability.can?(:new, 123).should be_true
    @ability.can?(:edit, 123).should be_true
  end

  it "should not respond to prepare (now using initialize)" do
    @ability.should_not respond_to(:prepare)
  end

  it "should offer cannot? method which is simply invert of can?" do
    @ability.cannot?(:tie, String).should be_true
  end

  it "should be able to specify multiple actions and match any" do
    @ability.can [:read, :update], :all
    @ability.can?(:read, 123).should be_true
    @ability.can?(:update, 123).should be_true
    @ability.can?(:count, 123).should be_false
  end

  it "should be able to specify multiple classes and match any" do
    @ability.can :update, [String, Range]
    @ability.can?(:update, "foo").should be_true
    @ability.can?(:update, 1..3).should be_true
    @ability.can?(:update, 123).should be_false
  end

  it "should support custom objects in the rule" do
    @ability.can :read, :stats
    @ability.can?(:read, :stats).should be_true
    @ability.can?(:update, :stats).should be_false
    @ability.can?(:read, :nonstats).should be_false
  end

  it "should check ancestors of class" do
    @ability.can :read, Numeric
    @ability.can?(:read, Integer).should be_true
    @ability.can?(:read, 1.23).should be_true
    @ability.can?(:read, "foo").should be_false
  end

  it "should support 'cannot' method to define what user cannot do" do
    @ability.can :read, :all
    @ability.cannot :read, Integer
    @ability.can?(:read, "foo").should be_true
    @ability.can?(:read, 123).should be_false
  end

  it "should pass to previous rule, if block returns false or nil" do
    @ability.can :read, :all
    @ability.cannot :read, Integer do |int|
      int > 10 ? nil : ( int > 5 )
    end
    @ability.can?(:read, "foo").should be_true
    @ability.can?(:read, 3).should be_true
    @ability.can?(:read, 8).should be_false
    @ability.can?(:read, 123).should be_true
  end

  it "should always return `false` for single cannot definition" do
    @ability.cannot :read, Integer do |int|
      int > 10 ? nil : ( int > 5 )
    end
    @ability.can?(:read, "foo").should be_false
    @ability.can?(:read, 3).should be_false
    @ability.can?(:read, 8).should be_false
    @ability.can?(:read, 123).should be_false
  end

  it "should pass to previous cannot definition, if block returns false or nil" do
    @ability.cannot :read, :all
    @ability.can :read, Integer do |int|
      int > 10 ? nil : ( int > 5 )
    end
    @ability.can?(:read, "foo").should be_false
    @ability.can?(:read, 3).should be_false
    @ability.can?(:read, 10).should be_true
    @ability.can?(:read, 123).should be_false
  end

  it "should append aliased actions" do
    @ability.alias_action :update, :to => :modify
    @ability.alias_action :destroy, :to => :modify
    @ability.aliased_actions[:modify].should == [:update, :destroy]
  end

  it "should clear aliased actions" do
    @ability.alias_action :update, :to => :modify
    @ability.clear_aliased_actions
    @ability.aliased_actions[:modify].should be_nil
  end

  it "should pass additional arguments to block from can?" do
    @ability.can :read, Integer do |int, x|
      int > x
    end
    @ability.can?(:read, 2, 1).should be_true
    @ability.can?(:read, 2, 3).should be_false
  end

  it "should use conditions as third parameter and determine abilities from it" do
    @ability.can :read, Range, :begin => 1, :end => 3
    @ability.can?(:read, 1..3).should be_true
    @ability.can?(:read, 1..4).should be_false
    @ability.can?(:read, Range).should be_true
  end

  it "should allow an array of options in conditions hash" do
    @ability.can :read, Range, :begin => [1, 3, 5]
    @ability.can?(:read, 1..3).should be_true
    @ability.can?(:read, 2..4).should be_false
    @ability.can?(:read, 3..5).should be_true
  end

  it "should allow a range of options in conditions hash" do
    @ability.can :read, Range, :begin => 1..3
    @ability.can?(:read, 1..10).should be_true
    @ability.can?(:read, 3..30).should be_true
    @ability.can?(:read, 4..40).should be_false
  end

  it "should allow nested hashes in conditions hash" do
    @ability.can :read, Range, :begin => { :to_i => 5 }
    @ability.can?(:read, 5..7).should be_true
    @ability.can?(:read, 6..8).should be_false
  end

  it "should match any element passed in to nesting if it's an array (for has_many associations)" do
    @ability.can :read, Range, :to_a => { :to_i => 3 }
    @ability.can?(:read, 1..5).should be_true
    @ability.can?(:read, 4..6).should be_false
  end
  
  it "should not match subjects return nil for methods that must match nested a nested conditions hash" do
    mock(object_with_foo = Object.new).foo { :bar }
    @ability.can :read, Array, :first => { :foo => :bar }
    @ability.can?(:read, [object_with_foo]).should be_true
    @ability.can?(:read, []).should be_false
  end

  it "should not stop at cannot definition when comparing class" do
    @ability.can :read, Range
    @ability.cannot :read, Range, :begin => 1
    @ability.can?(:read, 2..5).should be_true
    @ability.can?(:read, 1..5).should be_false
    @ability.can?(:read, Range).should be_true
  end

  it "should stop at cannot definition when no hash is present" do
    @ability.can :read, :all
    @ability.cannot :read, Range
    @ability.can?(:read, 1..5).should be_false
    @ability.can?(:read, Range).should be_false
  end

  it "should allow to check ability for Module" do
    module B; end
    class A; include B; end
    @ability.can :read, B
    @ability.can?(:read, A).should be_true
    @ability.can?(:read, A.new).should be_true
  end

  it "should pass nil to a block for ability on Module when no instance is passed" do
    module B; end
    class A; include B; end
    @ability.can :read, B do |sym|
      sym.should be_nil
      true
    end
    @ability.can?(:read, B).should be_true
    @ability.can?(:read, A).should be_true
  end

  it "passing a hash of subjects should check permissions through association" do
    @ability.can :read, Range, :string => {:length => 3}
    @ability.can?(:read, "foo" => Range).should be_true
    @ability.can?(:read, "foobar" => Range).should be_false
    @ability.can?(:read, 123 => Range).should be_true
  end
  
  it "should allow to check ability on Hash-like object" do
    class Container < Hash; end
    @ability.can :read, Container
    @ability.can?(:read, Container.new).should be_true
  end

  it "should have initial attributes based on hash conditions of 'new' action" do
    @ability.can :manage, Range, :foo => "foo", :hash => {:skip => "hashes"}
    @ability.can :create, Range, :bar => 123, :array => %w[skip arrays]
    @ability.can :new, Range, :baz => "baz", :range => 1..3
    @ability.cannot :new, Range, :ignore => "me"
    @ability.attributes_for(:new, Range).should == {:foo => "foo", :bar => 123, :baz => "baz"}
  end

  it "should raise access denied exception if ability us unauthorized to perform a certain action" do
    begin
      @ability.authorize! :read, :foo, 1, 2, 3, :message => "Access denied!"
    rescue CanCan::AccessDenied => e
      e.message.should == "Access denied!"
      e.action.should == :read
      e.subject.should == :foo
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "should not raise access denied exception if ability is authorized to perform an action and return subject" do
    @ability.can :read, :foo
    lambda {
      @ability.authorize!(:read, :foo).should == :foo
    }.should_not raise_error
  end

  it "should know when block is used in conditions" do
    @ability.can :read, :foo
    @ability.should_not have_block(:read, :foo)
    @ability.can :read, :foo do |foo|
      false
    end
    @ability.should have_block(:read, :foo)
  end

  it "should know when raw sql is used in conditions" do
    @ability.can :read, :foo
    @ability.should_not have_raw_sql(:read, :foo)
    @ability.can :read, :foo, 'false'
    @ability.should have_raw_sql(:read, :foo)
  end

  it "should raise access denied exception with default message if not specified" do
    begin
      @ability.authorize! :read, :foo
    rescue CanCan::AccessDenied => e
      e.default_message = "Access denied!"
      e.message.should == "Access denied!"
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "should determine model adapter class by asking AbstractAdapter" do
    model_class = Object.new
    adapter_class = Object.new
    stub(CanCan::ModelAdapters::AbstractAdapter).adapter_class(model_class) { adapter_class }
    stub(adapter_class).new(model_class, []) { :adapter_instance }
    @ability.model_adapter(model_class, :read).should == :adapter_instance
  end

  it "should raise an error when attempting to use a block with a hash condition since it's not likely what they want" do
    lambda {
      @ability.can :read, Array, :published => true do
        false
      end
    }.should raise_error(CanCan::Error, "You are not able to supply a block with a hash of conditions in read Array ability. Use either one.")
  end

  describe "unauthorized message" do
    after(:each) do
      I18n.backend = nil
    end

    it "should use action/subject in i18n" do
      I18n.backend.store_translations :en, :unauthorized => {:update => {:array => "foo"}}
      @ability.unauthorized_message(:update, Array).should == "foo"
      @ability.unauthorized_message(:update, [1, 2, 3]).should == "foo"
      @ability.unauthorized_message(:update, :missing).should be_nil
    end

    it "should use symbol as subject directly" do
      I18n.backend.store_translations :en, :unauthorized => {:has => {:cheezburger => "Nom nom nom. I eated it."}}
      @ability.unauthorized_message(:has, :cheezburger).should == "Nom nom nom. I eated it."
    end

    it "should fall back to 'manage' and 'all'" do
      I18n.backend.store_translations :en, :unauthorized => {
        :manage => {:all => "manage all", :array => "manage array"},
        :update => {:all => "update all", :array => "update array"}
      }
      @ability.unauthorized_message(:update, Array).should == "update array"
      @ability.unauthorized_message(:update, Hash).should == "update all"
      @ability.unauthorized_message(:foo, Array).should == "manage array"
      @ability.unauthorized_message(:foo, Hash).should == "manage all"
    end

    it "should follow aliased actions" do
      I18n.backend.store_translations :en, :unauthorized => {:modify => {:array => "modify array"}}
      @ability.alias_action :update, :to => :modify
      @ability.unauthorized_message(:update, Array).should == "modify array"
      @ability.unauthorized_message(:edit, Array).should == "modify array"
    end

    it "should have variables for action and subject" do
      I18n.backend.store_translations :en, :unauthorized => {:manage => {:all => "%{action} %{subject}"}} # old syntax for now in case testing with old I18n
      @ability.unauthorized_message(:update, Array).should == "update array"
      @ability.unauthorized_message(:update, ArgumentError).should == "update argument error"
      @ability.unauthorized_message(:edit, 1..3).should == "edit range"
    end
  end
end
