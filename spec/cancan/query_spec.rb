require "spec_helper"

describe CanCan::Query do
  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end
  
  it "should return array of behavior and conditions for a given ability" do
    @ability.can :read, Person, :first => 1, :last => 3
    @ability.query(:show, Person).conditions.should == [[true, {:first => 1, :last => 3}]]
  end
  
  it "should raise an exception when a block is used on condition, and no hash" do
    @ability.can :read, Person do |a|
      true
    end
    lambda { @ability.query(:show, Person).conditions }.should raise_error(CanCan::Error, "Cannot determine SQL conditions or joins from block for :show Person")
  end
  
  it "should return an array with just behavior for conditions when there are no conditions" do
    @ability.can :read, Person
    @ability.query(:show, Person).conditions.should == [ [true, {}] ]
  end

  it "should return false when performed on an action which isn't defined" do
    @ability.query(:foo, Person).conditions.should == false
  end
  
  it "should return hash for single `can` definition" do
    @ability.can :read, Person, :blocked => false, :user_id => 1
    
    @ability.query(:read, Person).sql_conditions.should == { :blocked => false, :user_id => 1 }    
  end
  
  it "should return `sql` for single `can` definition in front of default `cannot` condition" do
    @ability.cannot :read, Person
    @ability.can :read, Person, :blocked => false, :user_id => 1
    
    result = @ability.query(:read, Person).sql_conditions
    result.should include("blocked=false")
    result.should include(" AND ")
    result.should include("user_id=1")
  end 

  it "should return `true condition` for single `can` definition in front of default `can` condition" do
    @ability.can :read, Person
    @ability.can :read, Person, :blocked => false, :user_id => 1
    
    @ability.query(:read, Person).sql_conditions.should == 'true=true'
  end 

  it "should return `false condition` for single `cannot` definition" do
    @ability.cannot :read, Person, :blocked => true, :user_id => 1
    
    @ability.query(:read, Person).sql_conditions.should == 'true=false'
  end
  
  it "should return `false condition` for single `cannot` definition in front of default `cannot` condition" do
    @ability.cannot :read, Person
    @ability.cannot :read, Person, :blocked => true, :user_id => 1
    
    @ability.query(:read, Person).sql_conditions.should == 'true=false'
  end
  
  it "should return `not (sql)` for single `cannot` definition in front of default `can` condition" do
    @ability.can :read, Person
    @ability.cannot :read, Person, :blocked => true, :user_id => 1
    
    result = @ability.query(:read, Person).sql_conditions
    result.should include("not ")
    result.should include("blocked=true")
    result.should include(" AND ")
    result.should include("user_id=1")
  end
  
  it "should return appropriate sql conditions in complex case" do
    @ability.can :read, Person
    @ability.can :manage, Person, :id => 1
    @ability.can :update, Person, :manager_id => 1
    @ability.cannot :update, Person, :self_managed => true
    
    @ability.query(:update, Person).sql_conditions.should == 'not (self_managed=true) AND ((manager_id=1) OR (id=1))'
    @ability.query(:manage, Person).sql_conditions.should == {:id=>1}
    @ability.query(:read, Person).sql_conditions.should == 'true=true'
  end
end
