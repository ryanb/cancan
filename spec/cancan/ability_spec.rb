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


  # Hash Association

  it "checks permission through association when hash is passed as subject" do
    @ability.can :read, :books, :range => {:begin => 3}
    @ability.can?(:read, (1..4) => :books).should be_false
    @ability.can?(:read, (3..5) => :books).should be_true
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

  it "raises CanCan::AccessDenied when calling authorize! on unauthorized action" do
    begin
      @ability.authorize! :read, :books, :message => "Access denied!"
    rescue CanCan::AccessDenied => e
      e.message.should == "Access denied!"
      e.action.should == :read
      e.subject.should == :books
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "raises access denied exception with default message if not specified" do
    begin
      @ability.authorize! :read, :books
    rescue CanCan::AccessDenied => e
      e.default_message = "Access denied!"
      e.message.should == "Access denied!"
    else
      fail "Expected CanCan::AccessDenied exception to be raised"
    end
  end

  it "does not raise access denied exception if ability is authorized to perform an action" do
    @ability.can :read, :books
    lambda { @ability.authorize!(:read, :books) }.should_not raise_error
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
    stub(CanCan::ModelAdapters::AbstractAdapter).adapter_class(model_class) { adapter_class }
    stub(adapter_class).new(model_class, []) { :adapter_instance }
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
end
