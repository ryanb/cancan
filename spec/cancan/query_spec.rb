require "spec_helper"

describe CanCan::Query do
  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should have false conditions if no abilities match" do
    @ability.query(:destroy, Person).conditions.should == "true=false"
  end

  it "should return hash for single `can` definition" do
    @ability.can :read, Person, :blocked => false, :user_id => 1
    @ability.query(:read, Person).conditions.should == { :blocked => false, :user_id => 1 }
  end

  it "should merge multiple can definitions into single SQL string joining with OR" do
    @ability.can :read, Person, :blocked => false
    @ability.can :read, Person, :admin => true
    @ability.query(:read, Person).conditions.should == "(admin=true) OR (blocked=false)"
  end

  it "should merge multiple can definitions into single SQL string joining with OR and AND" do
    @ability.can :read, Person, :blocked => false, :active => true
    @ability.can :read, Person, :admin => true
    @ability.query(:read, Person).conditions.should orderlessly_match("(blocked=false AND active=true) OR (admin=true)")
  end

  it "should merge multiple can definitions into single SQL string joining with OR and AND" do
    @ability.can :read, Person, :blocked => false, :active => true
    @ability.can :read, Person, :admin => true
    @ability.query(:read, Person).conditions.should orderlessly_match("(blocked=false AND active=true) OR (admin=true)")
  end

  it "should return false conditions for cannot clause" do
    @ability.cannot :read, Person
    @ability.query(:read, Person).conditions.should == "true=false"
  end

  it "should return SQL for single `can` definition in front of default `cannot` condition" do
    @ability.cannot :read, Person
    @ability.can :read, Person, :blocked => false, :user_id => 1
    @ability.query(:read, Person).conditions.should orderlessly_match("blocked=false AND user_id=1")
  end

  it "should return true condition for single `can` definition in front of default `can` condition" do
    @ability.can :read, Person
    @ability.can :read, Person, :blocked => false, :user_id => 1
    @ability.query(:read, Person).conditions.should == 'true=true'
  end

  it "should return false condition for single `cannot` definition" do
    @ability.cannot :read, Person, :blocked => true, :user_id => 1
    @ability.query(:read, Person).conditions.should == 'true=false'
  end

  it "should return `false condition` for single `cannot` definition in front of default `cannot` condition" do
    @ability.cannot :read, Person
    @ability.cannot :read, Person, :blocked => true, :user_id => 1
    @ability.query(:read, Person).conditions.should == 'true=false'
  end

  it "should return `not (sql)` for single `cannot` definition in front of default `can` condition" do
    @ability.can :read, Person
    @ability.cannot :read, Person, :blocked => true, :user_id => 1
    @ability.query(:read, Person).conditions.should orderlessly_match("not (blocked=true AND user_id=1)")
  end

  it "should return appropriate sql conditions in complex case" do
    @ability.can :read, Person
    @ability.can :manage, Person, :id => 1
    @ability.can :update, Person, :manager_id => 1
    @ability.cannot :update, Person, :self_managed => true
    @ability.query(:update, Person).conditions.should == 'not (self_managed=true) AND ((manager_id=1) OR (id=1))'
    @ability.query(:manage, Person).conditions.should == {:id=>1}
    @ability.query(:read, Person).conditions.should == 'true=true'
  end

  it "should have nil joins if no can definitions" do
    @ability.query(:read, Person).joins.should be_nil
  end

  it "should have nil joins if no nested hashes specified in conditions" do
    @ability.can :read, Person, :blocked => false
    @ability.can :read, Person, :admin => true
    @ability.query(:read, Person).joins.should be_nil
  end

  it "should merge separate joins into a single array" do
    @ability.can :read, Person, :project => { :blocked => false }
    @ability.can :read, Person, :company => { :admin => true }
    @ability.query(:read, Person).joins.inspect.should orderlessly_match([:company, :project].inspect)
  end

  it "should merge same joins into a single array" do
    @ability.can :read, Person, :project => { :blocked => false }
    @ability.can :read, Person, :project => { :admin => true }
    @ability.query(:read, Person).joins.should == [:project]
  end

  it "should merge complex, nested joins" do
    @ability.can :read, Person, :project => { :bar => {:test => true} }, :company => { :bar => {:test => true} }
    @ability.can :read, Person, :project => { :foo => {:bar => true}, :bar => {:zip => :zap} }
    @ability.query(:read, Person).joins.inspect.should orderlessly_match([{:project => [:bar, :foo]}, {:company => [:bar]}].inspect)
  end
end
