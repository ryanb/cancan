require "spec_helper"

describe CanCan::ActiveRecordAdditions do
  before(:each) do
    @model_class = Class.new
    stub(@model_class).scoped { :scoped_stub }
    @model_class.send(:include, CanCan::ActiveRecordAdditions)
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should call where(:id => nil) when no ability is defined so no records are found" do
    stub(@model_class).where(:id => nil).stub!.joins(nil) { :no_where }
    @model_class.accessible_by(@ability, :read).should == :no_where
  end

  it "should call where with matching ability conditions" do
    @ability.can :read, @model_class, :foo => {:bar => 1}
    stub(@model_class).where(:foos => { :bar => 1 }).stub!.joins([:foo]) { :found_records }
    @model_class.accessible_by(@ability, :read).should == :found_records
  end

  it "should default to :read ability and use scoped when where isn't available" do
    @ability.can :read, @model_class, :foo => {:bar => 1}
    stub(@model_class).scoped(:conditions => {:foos => {:bar => 1}}, :joins => [:foo]) { :found_records }
    @model_class.accessible_by(@ability).should == :found_records
  end
end
