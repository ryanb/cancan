require "spec_helper"

describe CanCan::Ability do
  before(:each) do
    (@ability = double).extend(CanCan::Ability)
  end

  it "is able to :read anything" do
    @ability.can :read, :all
    expect(@ability.can?(:read, String)).to be_true
    expect(@ability.can?(:read, 123)).to be_true
  end

  it "does not have permission to do something it doesn't know about" do
    expect(@ability.can?(:foodfight, String)).to be_false
  end

  it "passes true to `can?` when non false/nil is returned in block" do
    @ability.can :read, :all
    @ability.can :read, Symbol do |sym|
      "foo" # TODO test that sym is nil when no instance is passed
    end
    expect(@ability.can?(:read, :some_symbol)).to be_true
  end

  it "passes nil to a block when no instance is passed" do
    @ability.can :read, Symbol do |sym|
      expect(sym).to be_nil
      true
    end
    expect(@ability.can?(:read, Symbol)).to be_true
  end

  it "passes to previous rule, if block returns false or nil" do
    @ability.can :read, Symbol
    @ability.can :read, Integer do |i|
      i < 5
    end
    @ability.can :read, Integer do |i|
      i > 10
    end
    expect(@ability.can?(:read, Symbol)).to be_true
    expect(@ability.can?(:read, 11)).to be_true
    expect(@ability.can?(:read, 1)).to be_true
    expect(@ability.can?(:read, 6)).to be_false
  end

  it "does not pass class with object if :all objects are accepted" do
    @ability.can :preview, :all do |object|
      expect(object).to eq(123)
      @block_called = true
    end
    @ability.can?(:preview, 123)
    expect(@block_called).to be_true
  end

  it "does not call block when only class is passed, only return true" do
    @block_called = false
    @ability.can :preview, :all do |object|
      @block_called = true
    end
    expect(@ability.can?(:preview, Hash)).to be_true
    expect(@block_called).to be_false
  end

  it "passes only object for global manage actions" do
    @ability.can :manage, String do |object|
      expect(object).to eq("foo")
      @block_called = true
    end
    expect(@ability.can?(:stuff, "foo")).to be_true
    expect(@block_called).to be_true
  end

  it "makes alias for update or destroy actions to modify action" do
    @ability.alias_action :update, :destroy, :to => :modify
    @ability.can :modify, :all
    expect(@ability.can?(:update, 123)).to be_true
    expect(@ability.can?(:destroy, 123)).to be_true
  end

  it "allows deeply nested aliased actions" do
    @ability.alias_action :increment, :to => :sort
    @ability.alias_action :sort, :to => :modify
    @ability.can :modify, :all
    expect(@ability.can?(:increment, 123)).to be_true
  end

  it "raises an Error if alias target is an exist action" do
    expect { @ability.alias_action :show, :to => :show }.to raise_error(CanCan::Error, "You can't specify target (show) as alias because it is real action name")
  end

  it "always calls block with arguments when passing no arguments to can" do
    @ability.can do |action, object_class, object|
      expect(action).to eq(:foo)
      expect(object_class).to eq(123.class)
      expect(object).to eq(123)
      @block_called = true
    end
    @ability.can?(:foo, 123)
    expect(@block_called).to be_true
  end

  it "passes nil to object when comparing class with can check" do
    @ability.can do |action, object_class, object|
      expect(action).to eq(:foo)
      expect(object_class).to eq(Hash)
      expect(object).to be_nil
      @block_called = true
    end
    @ability.can?(:foo, Hash)
    expect(@block_called).to be_true
  end

  it "automatically makes alias for index and show into read calls" do
    @ability.can :read, :all
    expect(@ability.can?(:index, 123)).to be_true
    expect(@ability.can?(:show, 123)).to be_true
  end

  it "automatically makes alias for new and edit into create and update respectively" do
    @ability.can :create, :all
    @ability.can :update, :all
    expect(@ability.can?(:new, 123)).to be_true
    expect(@ability.can?(:edit, 123)).to be_true
  end

  it "does not respond to prepare (now using initialize)" do
    expect(@ability).to_not respond_to(:prepare)
  end

  it "offers cannot? method which is simply invert of can?" do
    expect(@ability.cannot?(:tie, String)).to be_true
  end

  it "is able to specify multiple actions and match any" do
    @ability.can [:read, :update], :all
    expect(@ability.can?(:read, 123)).to be_true
    expect(@ability.can?(:update, 123)).to be_true
    expect(@ability.can?(:count, 123)).to be_false
  end

  it "is able to specify multiple classes and match any" do
    @ability.can :update, [String, Range]
    expect(@ability.can?(:update, "foo")).to be_true
    expect(@ability.can?(:update, 1..3)).to be_true
    expect(@ability.can?(:update, 123)).to be_false
  end

  it "supports custom objects in the rule" do
    @ability.can :read, :stats
    expect(@ability.can?(:read, :stats)).to be_true
    expect(@ability.can?(:update, :stats)).to be_false
    expect(@ability.can?(:read, :nonstats)).to be_false
  end

  it "checks ancestors of class" do
    @ability.can :read, Numeric
    expect(@ability.can?(:read, Integer)).to be_true
    expect(@ability.can?(:read, 1.23)).to be_true
    expect(@ability.can?(:read, "foo")).to be_false
  end

  it "supports 'cannot' method to define what user cannot do" do
    @ability.can :read, :all
    @ability.cannot :read, Integer
    expect(@ability.can?(:read, "foo")).to be_true
    expect(@ability.can?(:read, 123)).to be_false
  end

  it "passes to previous rule, if block returns false or nil" do
    @ability.can :read, :all
    @ability.cannot :read, Integer do |int|
      int > 10 ? nil : ( int > 5 )
    end
    expect(@ability.can?(:read, "foo")).to be_true
    expect(@ability.can?(:read, 3)).to be_true
    expect(@ability.can?(:read, 8)).to be_false
    expect(@ability.can?(:read, 123)).to be_true
  end

  it "always returns `false` for single cannot definition" do
    @ability.cannot :read, Integer do |int|
      int > 10 ? nil : ( int > 5 )
    end
    expect(@ability.can?(:read, "foo")).to be_false
    expect(@ability.can?(:read, 3)).to be_false
    expect(@ability.can?(:read, 8)).to be_false
    expect(@ability.can?(:read, 123)).to be_false
  end

  it "passes to previous cannot definition, if block returns false or nil" do
    @ability.cannot :read, :all
    @ability.can :read, Integer do |int|
      int > 10 ? nil : ( int > 5 )
    end
    expect(@ability.can?(:read, "foo")).to be_false
    expect(@ability.can?(:read, 3)).to be_false
    expect(@ability.can?(:read, 10)).to be_true
    expect(@ability.can?(:read, 123)).to be_false
  end

  it "appends aliased actions" do
    @ability.alias_action :update, :to => :modify
    @ability.alias_action :destroy, :to => :modify
    expect(@ability.aliased_actions[:modify]).to eq([:update, :destroy])
  end

  it "clears aliased actions" do
    @ability.alias_action :update, :to => :modify
    @ability.clear_aliased_actions
    expect(@ability.aliased_actions[:modify]).to be_nil
  end

  it "passes additional arguments to block from can?" do
    @ability.can :read, Integer do |int, x|
      int > x
    end
    expect(@ability.can?(:read, 2, 1)).to be_true
    expect(@ability.can?(:read, 2, 3)).to be_false
  end

  it "uses conditions as third parameter and determine abilities from it" do
    @ability.can :read, Range, :begin => 1, :end => 3
    expect(@ability.can?(:read, 1..3)).to be_true
    expect(@ability.can?(:read, 1..4)).to be_false
    expect(@ability.can?(:read, Range)).to be_true
  end

  it "allows an array of options in conditions hash" do
    @ability.can :read, Range, :begin => [1, 3, 5]
    expect(@ability.can?(:read, 1..3)).to be_true
    expect(@ability.can?(:read, 2..4)).to be_false
    expect(@ability.can?(:read, 3..5)).to be_true
  end

  it "allows a range of options in conditions hash" do
    @ability.can :read, Range, :begin => 1..3
    expect(@ability.can?(:read, 1..10)).to be_true
    expect(@ability.can?(:read, 3..30)).to be_true
    expect(@ability.can?(:read, 4..40)).to be_false
  end

  it "allows nested hashes in conditions hash" do
    @ability.can :read, Range, :begin => { :to_i => 5 }
    expect(@ability.can?(:read, 5..7)).to be_true
    expect(@ability.can?(:read, 6..8)).to be_false
  end

  it "matches any element passed in to nesting if it's an array (for has_many associations)" do
    @ability.can :read, Range, :to_a => { :to_i => 3 }
    expect(@ability.can?(:read, 1..5)).to be_true
    expect(@ability.can?(:read, 4..6)).to be_false
  end

  it "accepts a set as a condition value" do
    expect(object_with_foo_2 = double(:foo => 2)).to receive(:foo)
    expect(object_with_foo_3 = double(:foo => 3)).to receive(:foo) 
    @ability.can :read, Object, :foo => [1, 2, 5].to_set
    expect(@ability.can?(:read, object_with_foo_2)).to be_true
    expect(@ability.can?(:read, object_with_foo_3)).to be_false
  end

  it "does not match subjects return nil for methods that must match nested a nested conditions hash" do
    expect(object_with_foo = double(:foo => :bar)).to receive(:foo)
    @ability.can :read, Array, :first => { :foo => :bar }
    expect(@ability.can?(:read, [object_with_foo])).to be_true
    expect(@ability.can?(:read, [])).to be_false
  end

  it "matches strings but not substrings specified in a conditions hash" do
    @ability.can :read, String, :presence => "declassified"
    expect(@ability.can?(:read, "declassified")).to be_true
    expect(@ability.can?(:read, "classified")).to be_false
  end

  it "does not stop at cannot definition when comparing class" do
    @ability.can :read, Range
    @ability.cannot :read, Range, :begin => 1
    expect(@ability.can?(:read, 2..5)).to be_true
    expect(@ability.can?(:read, 1..5)).to be_false
    expect(@ability.can?(:read, Range)).to be_true
  end

  it "stops at cannot definition when no hash is present" do
    @ability.can :read, :all
    @ability.cannot :read, Range
    expect(@ability.can?(:read, 1..5)).to be_false
    expect(@ability.can?(:read, Range)).to be_false
  end

  it "allows to check ability for Module" do
    module B; end
    class A; include B; end
    @ability.can :read, B
    expect(@ability.can?(:read, A)).to be_true
    expect(@ability.can?(:read, A.new)).to be_true
  end

  it "passes nil to a block for ability on Module when no instance is passed" do
    module B; end
    class A; include B; end
    @ability.can :read, B do |sym|
      expect(sym).to be_nil
      true
    end
    expect(@ability.can?(:read, B)).to be_true
    expect(@ability.can?(:read, A)).to be_true
  end

  it "checks permissions through association when passing a hash of subjects" do
    @ability.can :read, Range, :string => {:length => 3}
    expect(@ability.can?(:read, "foo" => Range)).to be_true
    expect(@ability.can?(:read, "foobar" => Range)).to be_false
    expect(@ability.can?(:read, 123 => Range)).to be_true
  end

  it "checks permissions correctly when passing a hash of subjects with multiple definitions" do
    @ability.can :read, Range, :string => {:length => 4}
    @ability.can [:create, :read], Range, :string => {:upcase => 'FOO'}
    expect(@ability.can?(:read, "foo" => Range)).to be_true
    expect(@ability.can?(:read, "foobar" => Range)).to be_false
    expect(@ability.can?(:read, 1234 => Range)).to be_true
  end

  it "allows to check ability on Hash-like object" do
    class Container < Hash; end
    @ability.can :read, Container
    expect(@ability.can?(:read, Container.new)).to be_true
  end

  it "has initial attributes based on hash conditions of 'new' action" do
    @ability.can :manage, Range, :foo => "foo", :hash => {:skip => "hashes"}
    @ability.can :create, Range, :bar => 123, :array => %w[skip arrays]
    @ability.can :new, Range, :baz => "baz", :range => 1..3
    @ability.cannot :new, Range, :ignore => "me"
    expect(@ability.attributes_for(:new, Range)).to eq({:foo => "foo", :bar => 123, :baz => "baz"})
  end

  it "raises access denied exception if ability us unauthorized to perform a certain action" do
    begin
      @ability.authorize! :read, :foo, 1, 2, 3, :message => "Access denied!"
    rescue CanCan::AccessDenied => e
      expect(e.message).to eq("Access denied!")
      expect(e.action).to eq(:read)
      expect(e.subject).to eq(:foo)
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "does not raise access denied exception if ability is authorized to perform an action and return subject" do
    @ability.can :read, :foo
    expect {
      expect(@ability.authorize!(:read, :foo)).to eq(:foo)
    }.to_not raise_error
  end

  it "knows when block is used in conditions" do
    @ability.can :read, :foo
    expect(@ability).to_not have_block(:read, :foo)
    @ability.can :read, :foo do |foo|
      false
    end
    expect(@ability).to have_block(:read, :foo)
  end

  it "knows when raw sql is used in conditions" do
    @ability.can :read, :foo
    expect(@ability).to_not have_raw_sql(:read, :foo)
    @ability.can :read, :foo, 'false'
    expect(@ability).to have_raw_sql(:read, :foo)
  end

  it "raises access denied exception with default message if not specified" do
    begin
      @ability.authorize! :read, :foo
    rescue CanCan::AccessDenied => e
      e.default_message = "Access denied!"
      expect(e.message).to eq("Access denied!")
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "determines model adapterO class by asking AbstractAdapter" do
    adapter_class, model_class = double, double
    allow(CanCan::ModelAdapters::AbstractAdapter).to receive(:adapter_class).with(model_class) { adapter_class }
    allow(adapter_class).to receive(:new).with(model_class, []) { :adapter_instance }
    expect(@ability.model_adapter(model_class, :read)).to eq(:adapter_instance)
  end

  it "raises an error when attempting to use a block with a hash condition since it's not likely what they want" do
    expect {
      @ability.can :read, Array, :published => true do
        false
      end
    }.to raise_error(CanCan::Error, "You are not able to supply a block with a hash of conditions in read Array ability. Use either one.")
  end

  describe "unauthorized message" do
    after(:each) do
      I18n.backend = nil
    end

    it "uses action/subject in i18n" do
      I18n.backend.store_translations :en, :unauthorized => {:update => {:array => "foo"}}
      expect(@ability.unauthorized_message(:update, Array)).to eq("foo")
      expect(@ability.unauthorized_message(:update, [1, 2, 3])).to eq("foo")
      expect(@ability.unauthorized_message(:update, :missing)).to be_nil
    end

    it "uses symbol as subject directly" do
      I18n.backend.store_translations :en, :unauthorized => {:has => {:cheezburger => "Nom nom nom. I eated it."}}
      expect(@ability.unauthorized_message(:has, :cheezburger)).to eq("Nom nom nom. I eated it.")
    end

    it "falls back to 'manage' and 'all'" do
      I18n.backend.store_translations :en, :unauthorized => {
        :manage => {:all => "manage all", :array => "manage array"},
        :update => {:all => "update all", :array => "update array"}
      }
      expect(@ability.unauthorized_message(:update, Array)).to eq("update array")
      expect(@ability.unauthorized_message(:update, Hash)).to eq("update all")
      expect(@ability.unauthorized_message(:foo, Array)).to eq("manage array")
      expect(@ability.unauthorized_message(:foo, Hash)).to eq("manage all")
    end

    it "follows aliased actions" do
      I18n.backend.store_translations :en, :unauthorized => {:modify => {:array => "modify array"}}
      @ability.alias_action :update, :to => :modify
      expect(@ability.unauthorized_message(:update, Array)).to eq("modify array")
      expect(@ability.unauthorized_message(:edit, Array)).to eq("modify array")
    end

    it "has variables for action and subject" do
      I18n.backend.store_translations :en, :unauthorized => {:manage => {:all => "%{action} %{subject}"}} # old syntax for now in case testing with old I18n
      expect(@ability.unauthorized_message(:update, Array)).to eq("update array")
      expect(@ability.unauthorized_message(:update, ArgumentError)).to eq("update argument error")
      expect(@ability.unauthorized_message(:edit, 1..3)).to eq("edit range")
    end
  end

  describe "#merge" do
    it "adds the rules from the given ability" do
      @ability.can :use, :tools
      (another_ability = double).extend(CanCan::Ability)
      another_ability.can :use, :search

      @ability.merge(another_ability)
      expect(@ability.can?(:use, :search)).to be_true
      expect(@ability.send(:rules).size).to eq(2)
    end
  end
end
