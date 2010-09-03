require "spec_helper"

describe CanCan::Query do
  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should have false conditions if no abilities match" do
    @ability.query(:destroy, Project).conditions.should == "true=false"
  end

  it "should return hash for single `can` definition" do
    @ability.can :read, Project, :blocked => false, :user_id => 1
    @ability.query(:read, Project).conditions.should == { :blocked => false, :user_id => 1 }
  end

  it "should merge multiple can definitions into single SQL string joining with OR" do
    @ability.can :read, Project, :blocked => false
    @ability.can :read, Project, :admin => true
    @ability.query(:read, Project).conditions.should == "(admin=true) OR (blocked=false)"
  end

  it "should merge multiple can definitions into single SQL string joining with OR and AND" do
    @ability.can :read, Project, :blocked => false, :active => true
    @ability.can :read, Project, :admin => true
    @ability.query(:read, Project).conditions.should orderlessly_match("(blocked=false AND active=true) OR (admin=true)")
  end

  it "should merge multiple can definitions into single SQL string joining with OR and AND" do
    @ability.can :read, Project, :blocked => false, :active => true
    @ability.can :read, Project, :admin => true
    @ability.query(:read, Project).conditions.should orderlessly_match("(blocked=false AND active=true) OR (admin=true)")
  end

  it "should return false conditions for cannot clause" do
    @ability.cannot :read, Project
    @ability.query(:read, Project).conditions.should == "true=false"
  end

  it "should return SQL for single `can` definition in front of default `cannot` condition" do
    @ability.cannot :read, Project
    @ability.can :read, Project, :blocked => false, :user_id => 1
    @ability.query(:read, Project).conditions.should orderlessly_match("blocked=false AND user_id=1")
  end

  it "should return true condition for single `can` definition in front of default `can` condition" do
    @ability.can :read, Project
    @ability.can :read, Project, :blocked => false, :user_id => 1
    @ability.query(:read, Project).conditions.should == 'true=true'
  end

  it "should return false condition for single `cannot` definition" do
    @ability.cannot :read, Project, :blocked => true, :user_id => 1
    @ability.query(:read, Project).conditions.should == 'true=false'
  end

  it "should return `false condition` for single `cannot` definition in front of default `cannot` condition" do
    @ability.cannot :read, Project
    @ability.cannot :read, Project, :blocked => true, :user_id => 1
    @ability.query(:read, Project).conditions.should == 'true=false'
  end

  it "should return `not (sql)` for single `cannot` definition in front of default `can` condition" do
    @ability.can :read, Project
    @ability.cannot :read, Project, :blocked => true, :user_id => 1
    @ability.query(:read, Project).conditions.should orderlessly_match("not (blocked=true AND user_id=1)")
  end

  it "should return appropriate sql conditions in complex case" do
    @ability.can :read, Project
    @ability.can :manage, Project, :id => 1
    @ability.can :update, Project, :manager_id => 1
    @ability.cannot :update, Project, :self_managed => true
    @ability.query(:update, Project).conditions.should == 'not (self_managed=true) AND ((manager_id=1) OR (id=1))'
    @ability.query(:manage, Project).conditions.should == {:id=>1}
    @ability.query(:read, Project).conditions.should == 'true=true'
  end

  it "should have nil joins if no can definitions" do
    @ability.query(:read, Project).joins.should be_nil
  end

  it "should have nil joins if no nested hashes specified in conditions" do
    @ability.can :read, Project, :blocked => false
    @ability.can :read, Project, :admin => true
    @ability.query(:read, Project).joins.should be_nil
  end

  it "should merge separate joins into a single array" do
    @ability.can :read, Project, :project => { :blocked => false }
    @ability.can :read, Project, :company => { :admin => true }
    @ability.query(:read, Project).joins.inspect.should orderlessly_match([:company, :project].inspect)
  end

  it "should merge same joins into a single array" do
    @ability.can :read, Project, :project => { :blocked => false }
    @ability.can :read, Project, :project => { :admin => true }
    @ability.query(:read, Project).joins.should == [:project]
  end

  it "should merge complex, nested joins" do
    @ability.can :read, Project, :project => { :bar => {:test => true} }, :company => { :bar => {:test => true} }
    @ability.can :read, Project, :project => { :foo => {:bar => true}, :bar => {:zip => :zap} }
    @ability.query(:read, Project).joins.inspect.should orderlessly_match([{:project => [:bar, :foo]}, {:company => [:bar]}].inspect)
  end
end
