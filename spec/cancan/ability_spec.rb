require "spec_helper"

describe CanCan::Ability do
  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end


  # Basic Action & Subject

  it "allows access to only what is defined" do
    @ability.can?(:paint, :fences).should be_false
    @ability.can :paint, :fences
    @ability.can?(:paint, :fences).should be_true
    @ability.can?(:wax, :fences).should be_false
    @ability.can?(:paint, :cars).should be_false
  end

  it "allows access to everything when :access, :all is used" do
    @ability.can?(:paint, :fences).should be_false
    @ability.can :access, :all
    @ability.can?(:paint, :fences).should be_true
    @ability.can?(:wax, :fences).should be_true
    @ability.can?(:paint, :cars).should be_true
  end

  it "allows access to multiple actions and subjects" do
    @ability.can [:paint, :sand], [:fences, :decks]
    @ability.can?(:paint, :fences).should be_true
    @ability.can?(:sand, :fences).should be_true
    @ability.can?(:paint, :decks).should be_true
    @ability.can?(:sand, :decks).should be_true
    @ability.can?(:wax, :fences).should be_false
    @ability.can?(:paint, :cars).should be_false
  end

  it "allows strings instead of symbols in ability check" do
    @ability.can :paint, :fences
    @ability.can?("paint", "fences").should be_true
  end


  # Aliases

  it "has default index, show, new, update, delete aliases" do
    @ability.can :read, :projects
    @ability.can?(:index, :projects).should be_true
    @ability.can?(:show, :projects).should be_true
    @ability.can :create, :projects
    @ability.can?(:new, :projects).should be_true
    @ability.can :update, :projects
    @ability.can?(:edit, :projects).should be_true
    @ability.can :destroy, :projects
    @ability.can?(:delete, :projects).should be_true
  end

  it "follows deep action aliases" do
    @ability.alias_action :update, :destroy, :to => :modify
    @ability.can :modify, :projects
    @ability.can?(:update, :projects).should be_true
    @ability.can?(:destroy, :projects).should be_true
    @ability.can?(:edit, :projects).should be_true
  end

  it "adds up action aliases" do
    @ability.alias_action :update, :to => :modify
    @ability.alias_action :destroy, :to => :modify
    @ability.can :modify, :projects
    @ability.can?(:update, :projects).should be_true
    @ability.can?(:destroy, :projects).should be_true
  end

  it "follows deep subject aliases" do
    @ability.alias_subject :mammals, :to => :animals
    @ability.alias_subject :cats, :to => :mammals
    @ability.can :pet, :animals
    @ability.can?(:pet, :mammals).should be_true
  end

  it "clears current and default aliases" do
    @ability.alias_action :update, :destroy, :to => :modify
    @ability.clear_aliases
    @ability.can :modify, :projects
    @ability.can?(:update, :projects).should be_false
    @ability.can :read, :projects
    @ability.can?(:show, :projects).should be_false
  end


  # Hash Conditions

  it "maps object to pluralized subject name" do
    @ability.can :read, :ranges
    @ability.can?(:read, :ranges).should be_true
    @ability.can?(:read, 1..3).should be_true
    @ability.can?(:read, 123).should be_false
  end

  it "checks conditions hash on instances only" do
    @ability.can :read, :ranges, :begin => 1
    @ability.can?(:read, :ranges).should be_true
    @ability.can?(:read, 1..3).should be_true
    @ability.can?(:read, 2..4).should be_false
  end

  it "checks conditions on both rules and matches either one" do
    @ability.can :read, :ranges, :begin => 1
    @ability.can :read, :ranges, :begin => 2
    @ability.can?(:read, 1..3).should be_true
    @ability.can?(:read, 2..4).should be_true
    @ability.can?(:read, 3..5).should be_false
  end

  it "checks an array of options in conditions hash" do
    @ability.can :read, :ranges, :begin => [1, 3, 5]
    @ability.can?(:read, 1..3).should be_true
    @ability.can?(:read, 2..4).should be_false
    @ability.can?(:read, 3..5).should be_true
  end

  it "checks a range of options in conditions hash" do
    @ability.can :read, :ranges, :begin => 1..3
    @ability.can?(:read, 1..10).should be_true
    @ability.can?(:read, 3..30).should be_true
    @ability.can?(:read, 4..40).should be_false
  end

  it "checks nested conditions hash" do
    @ability.can :read, :ranges, :begin => { :to_i => 5 }
    @ability.can?(:read, 5..7).should be_true
    @ability.can?(:read, 6..8).should be_false
  end

  it "matches any element passed in to nesting if it's an array (for has_many associations)" do
    @ability.can :read, :ranges, :to_a => { :to_i => 3 }
    @ability.can?(:read, 1..5).should be_true
    @ability.can?(:read, 4..6).should be_false
  end

  it "takes presedence over rule defined without a condition" do
    @ability.can :read, :ranges
    @ability.can :read, :ranges, :begin => 1
    @ability.can?(:read, 1..5).should be_true
    @ability.can?(:read, 4..6).should be_false
  end


  # Block Conditions

  it "executes block passing object only when instance is used" do
    @ability.can :read, :ranges do |range|
      range.begin == 5
    end
    @ability.can?(:read, :ranges).should be_true
    @ability.can?(:read, 5..7).should be_true
    @ability.can?(:read, 6..8).should be_false
  end

  it "returns true when other object is returned in block" do
    @ability.can :read, :ranges do |range|
      "foo"
    end
    @ability.can?(:read, 5..7).should be_true
  end

  it "passes to previous rule when block returns false" do
    @ability.can :read, :fixnums do |i|
      i < 5
    end
    @ability.can :read, :fixnums do |i|
      i > 10
    end
    @ability.can?(:read, 11).should be_true
    @ability.can?(:read, 1).should be_true
    @ability.can?(:read, 6).should be_false
  end

  it "calls block passing arguments when no arguments are given to can" do
    @ability.can do |action, subject, object|
      action.should == :read
      subject.should == :ranges
      object.should == (2..4)
      @block_called = true
    end
    @ability.can?(:read, 2..4)
    @block_called.should be_true
  end

  it "raises an error when attempting to use a block with a hash condition since it's not likely what they want" do
    lambda {
      @ability.can :read, :ranges, :published => true do
        false
      end
    }.should raise_error(CanCan::Error, "You are not able to supply a block with a hash of conditions in read ranges ability. Use either one.")
  end

  it "does not raise an error when attempting to use a block with an array of SQL conditions" do
    lambda {
      @ability.can :read, :ranges, ["published = ?", true] do
        false
      end
    }.should_not raise_error(CanCan::Error)
  end


  # Attributes

  it "allows permission on attributes" do
    @ability.can :update, :users, :name
    @ability.can :update, :users, [:email, :age]
    @ability.can?(:update, :users, :name).should be_true
    @ability.can?(:update, :users, :email).should be_true
    @ability.can?(:update, :users, :password).should be_false
  end

  it "allows permission on all attributes when none are given" do
    @ability.can :update, :users
    @ability.can?(:update, :users, :password).should be_true
  end

  it "allows strings when chekcing attributes" do
    @ability.can :update, :users, :name
    @ability.can?(:update, :users, "name").should be_true
  end

  it "combines attribute check with conditions hash" do
    @ability.can :update, :ranges, :begin => 1
    @ability.can :update, :ranges, :name, :begin => 2
    @ability.can?(:update, 1..3, :foobar).should be_true
    @ability.can?(:update, 2..4, :foobar).should be_false
    @ability.can?(:update, 2..4, :name).should be_true
    @ability.can?(:update, 3..5, :name).should be_false
  end

  it "passes attribute to block and nil if no attribute checked" do
    @ability.can :update, :ranges do |range, attribute|
      attribute == :name
    end
    @ability.can?(:update, 1..3, :name).should be_true
    @ability.can?(:update, 2..4).should be_false
  end

  it "passes attribute to block for global can definition" do
    @ability.can do |action, subject, object, attribute|
      attribute == :name
    end
    @ability.can?(:update, 1..3, :name).should be_true
    @ability.can?(:update, 2..4).should be_false
  end


  # Checking if Fully Authorized

  it "is not fully authorized when no authorize! call is made" do
    @ability.can :update, :ranges, :begin => 1
    @ability.can?(:update, :ranges).should be_true
    @ability.should_not be_fully_authorized(:update, :ranges)
  end

  it "is fully authorized when calling authorize! with a matching action and subject" do
    @ability.can :update, :ranges
    @ability.authorize! :update, :ranges
    @ability.should be_fully_authorized(:update, :ranges)
    @ability.should_not be_fully_authorized(:create, :ranges)
  end

  it "is fully authorized when marking action and subject as such" do
    @ability.fully_authorized! :update, :ranges
    @ability.should be_fully_authorized(:update, :ranges)
  end

  it "is not fully authorized when a conditions hash exists but no instance is used" do
    @ability.can :update, :ranges, :begin => 1
    @ability.authorize! :update, :ranges
    @ability.should_not be_fully_authorized(:update, :ranges)
    @ability.authorize! "update", "ranges"
    @ability.should_not be_fully_authorized(:update, :ranges)
    @ability.authorize! :update, 1..3
    @ability.should be_fully_authorized(:update, :ranges)
  end

  it "is not fully authorized when a block exists but no instance is used" do
    @ability.can :update, :ranges do |range|
      range.begin == 1
    end
    @ability.authorize! :update, :ranges
    @ability.should_not be_fully_authorized(:update, :ranges)
    @ability.authorize! :update, 1..3
    @ability.should be_fully_authorized(:update, :ranges)
  end

  it "should accept a set as a condition value" do
    object_with_foo_2 = Object.new
    object_with_foo_2.should_receive(:foo) { 2 }
    object_with_foo_3 = Object.new
    object_with_foo_3.should_receive(:foo) { 3 }
    @ability.can :read, :objects, :foo => [1, 2, 5].to_set
    @ability.can?(:read, object_with_foo_2).should be_true
    @ability.can?(:read, object_with_foo_3).should be_false
  end

  it "does not match subjects return nil for methods that must match nested a nested conditions hash" do
    object_with_foo = Object.new
    object_with_foo.should_receive(:foo) { :bar }
    @ability.can :read, :arrays, :first => { :foo => :bar }
    @ability.can?(:read, [object_with_foo]).should be_true
    @ability.can?(:read, []).should be_false
  end

  it "is not fully authorized when attributes are required but not checked in update/create actions" do
    @ability.can :access, :users, :name
    @ability.authorize! :update, :users
    @ability.should_not be_fully_authorized(:update, :users)
    @ability.authorize! :create, :users
    @ability.should_not be_fully_authorized(:create, :users)
    @ability.authorize! :create, :users, :name
    @ability.should be_fully_authorized(:create, :users)
    @ability.authorize! :destroy, :users
    @ability.should be_fully_authorized(:destroy, :users)
  end

  it "marks as fully authorized when authorizing with strings instead of symbols" do
    @ability.fully_authorized! "update", "ranges"
    @ability.should be_fully_authorized(:update, :ranges)
    @ability.should be_fully_authorized("update", "ranges")
    @ability.can :update, :users
    @ability.authorize! "update", "users"
    @ability.should be_fully_authorized(:update, :users)
  end


  # Cannot

  it "offers cannot? method which inverts can?" do
    @ability.cannot?(:wax, :cars).should be_true
  end

  it "supports 'cannot' method to define what user cannot do" do
    @ability.can :read, :all
    @ability.cannot :read, :ranges
    @ability.can?(:read, :books).should be_true
    @ability.can?(:read, 1..3).should be_false
    @ability.can?(:read, :ranges).should be_false
  end

  it "passes to previous rule if cannot check returns false" do
    @ability.can :read, :all
    @ability.cannot :read, :ranges, :begin => 3
    @ability.cannot :read, :ranges do |range|
      range.begin == 5
    end
    @ability.can?(:read, :books).should be_true
    @ability.can?(:read, 2..4).should be_true
    @ability.can?(:read, 3..7).should be_false
    @ability.can?(:read, 5..9).should be_false
  end

  it "rejects permission only to a given attribute" do
    @ability.can :update, :books
    @ability.cannot :update, :books, :author
    @ability.can?(:update, :books).should be_true
    @ability.can?(:update, :books, :author).should be_false
  end

  # Hash Association

  it "checks permission through association when hash is passed as subject" do
    @ability.can :read, :books, :range => {:begin => 3}
    @ability.can?(:read, (1..4) => :books).should be_false
    @ability.can?(:read, (3..5) => :books).should be_true
    @ability.can?(:read, 123 => :books).should be_true
  end

  it "checks permissions on association hash with multiple rules" do
    @ability.can :read, :books, :range => {:begin => 3}
    @ability.can :read, :books, :range => {:end => 6}
    @ability.can?(:read, (1..4) => :books).should be_false
    @ability.can?(:read, (3..5) => :books).should be_true
    @ability.can?(:read, (1..6) => :books).should be_true
    @ability.can?(:read, 123 => :books).should be_true
  end

  it "checks ability on hash subclass" do
    class Container < Hash; end
    @ability.can :read, :containers
    @ability.can?(:read, Container.new).should be_true
  end


  # Initial Attributes

  it "has initial attributes based on hash conditions for a given action" do
    @ability.can :access, :ranges, :foo => "foo", :hash => {:skip => "hashes"}
    @ability.can :create, :ranges, :bar => 123, :array => %w[skip arrays]
    @ability.can :new, :ranges, :baz => "baz", :range => 1..3
    @ability.cannot :new, :ranges, :ignore => "me"
    @ability.attributes_for(:new, :ranges).should == {:foo => "foo", :bar => 123, :baz => "baz"}
  end


  # Unauthorized Exception

  it "raises CanCan::Unauthorized when calling authorize! on unauthorized action" do
    begin
      @ability.authorize! :read, :books, :message => "Access denied!"
    rescue CanCan::Unauthorized => e
      e.message.should == "Access denied!"
      e.action.should == :read
      e.subject.should == :books
    else
      fail "Expected CanCan::Unauthorized exception to be raised"
    end
  end

  it "does not raise access denied exception if ability is authorized to perform an action and return subject" do
    @ability.can :read, :foo
    lambda {
      @ability.authorize!(:read, :foo).should == :foo
    }.should_not raise_error
  end

  it "knows when block is used in conditions" do
    @ability.can :read, :foo
    @ability.should_not have_block(:read, :foo)
    @ability.can :read, :foo do |foo|
      false
    end
    @ability.should have_block(:read, :foo)
  end

  it "knows when raw sql is used in conditions" do
    @ability.can :read, :foo
    @ability.should_not have_raw_sql(:read, :foo)
    @ability.can :read, :foo, 'false'
    @ability.should have_raw_sql(:read, :foo)
  end

  it "raises access denied exception with default message if not specified" do
    begin
      @ability.authorize! :read, :books
    rescue CanCan::Unauthorized => e
      e.default_message = "Access denied!"
      e.message.should == "Access denied!"
    else
      fail "Expected CanCan::Unauthorized exception to be raised"
    end
  end

  it "does not raise access denied exception if ability is authorized to perform an action and return subject" do
    @ability.can :read, :books
    lambda {
      @ability.authorize!(:read, :books).should == :books
    }.should_not raise_error
  end


  # Determining Kind of Conditions

  it "knows when a block is used for conditions" do
    @ability.can :read, :books
    @ability.should_not have_block(:read, :books)
    @ability.can :read, :books do |foo|
      false
    end
    @ability.should have_block(:read, :books)
  end

  it "knows when raw sql is used for conditions" do
    @ability.can :read, :books
    @ability.should_not have_raw_sql(:read, :books)
    @ability.can :read, :books, 'false'
    @ability.should have_raw_sql(:read, :books)
  end

  it "determines model adapter class by asking AbstractAdapter" do
    model_class = Object.new
    adapter_class = Object.new
    CanCan::ModelAdapters::AbstractAdapter.stub(:adapter_class).with(model_class) { adapter_class }
    adapter_class.stub(:new).with(model_class, []) { :adapter_instance }
    @ability.model_adapter(model_class, :read).should == :adapter_instance
  end


  # Unauthorized I18n Message

  describe "unauthorized message" do
    after(:each) do
      I18n.backend = nil
    end

    it "uses action/subject in i18n" do
      I18n.backend.store_translations :en, :unauthorized => {:update => {:ranges => "update ranges"}}
      @ability.unauthorized_message(:update, :ranges).should == "update ranges"
      @ability.unauthorized_message(:update, 2..4).should == "update ranges"
      @ability.unauthorized_message(:update, :missing).should be_nil
    end

    it "uses symbol as subject directly" do
      I18n.backend.store_translations :en, :unauthorized => {:has => {:cheezburger => "Nom nom nom. I eated it."}}
      @ability.unauthorized_message(:has, :cheezburger).should == "Nom nom nom. I eated it."
    end

    it "falls back to 'access' and 'all'" do
      I18n.backend.store_translations :en, :unauthorized => {
        :access => {:all => "access all", :ranges => "access ranges"},
        :update => {:all => "update all", :ranges => "update ranges"}
      }
      @ability.unauthorized_message(:update, :ranges).should == "update ranges"
      @ability.unauthorized_message(:update, :hashes).should == "update all"
      @ability.unauthorized_message(:create, :ranges).should == "access ranges"
      @ability.unauthorized_message(:create, :hashes).should == "access all"
    end

    it "follows aliases" do
      I18n.backend.store_translations :en, :unauthorized => {:modify => {:ranges => "modify ranges"}}
      @ability.alias_action :update, :to => :modify
      @ability.alias_subject :areas, :to => :ranges
      @ability.unauthorized_message(:update, :areas).should == "modify ranges"
      @ability.unauthorized_message(:edit, :ranges).should == "modify ranges"
    end

    it "has variables for action and subject" do
      I18n.backend.store_translations :en, :unauthorized => {:access => {:all => "%{action} %{subject}"}} # old syntax for now in case testing with old I18n
      @ability.unauthorized_message(:update, :ranges).should == "update ranges"
      @ability.unauthorized_message(:edit, 1..3).should == "edit ranges"
      # @ability.unauthorized_message(:update, ArgumentError).should == "update argument error"
    end
  end

  it "merges the rules from another ability" do
    @ability.can :use, :tools
    another_ability = Object.new
    another_ability.extend(CanCan::Ability)
    another_ability.can :use, :search

    @ability.merge(another_ability)
    @ability.can?(:use, :search).should be_true
    @ability.send(:rules).size.should == 2
  end
end
