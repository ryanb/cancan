require "spec_helper"

# Most of Rule functionality is tested in Ability specs
describe CanCan::Rule do
  before(:each) do
    @conditions = {}
    @rule = CanCan::Rule.new(true, :read, Integer, @conditions, nil)
  end

  it "should return no association joins if none exist" do
    @rule.associations_hash.should == {}
  end

  it "should return no association for joins if just attributes" do
    @conditions[:foo] = :bar
    @rule.associations_hash.should == {}
  end

  it "should return single association for joins" do
    @conditions[:foo] = {:bar => 1}
    @rule.associations_hash.should == {:foo => {}}
  end

  it "should return multiple associations for joins" do
    @conditions[:foo] = {:bar => 1}
    @conditions[:test] = {1 => 2}
    @rule.associations_hash.should == {:foo => {}, :test => {}}
  end

  it "should return nested associations for joins" do
    @conditions[:foo] = {:bar => {1 => 2}}
    @rule.associations_hash.should == {:foo => {:bar => {}}}
  end

  it "should tableize correctly for absurdly complex permissions" do
    @conditions[:unit] = {:property=>{:landlord=>{:weasle_id=>560}}}
    @conditions[:test] = 1
    @rule.tableized_conditions.should == {:units => {:properties => {:landlords=>{:weasle_id=>560}}}, :test => 1}
  end

  it "should tableize correctly for complex permissions" do
    @conditions[:unit] = {:property=>{:landlord_id=>560}}
    @conditions[:test] = 1
    @rule.tableized_conditions.should == {:units => {:properties => {:landlord_id=>560}}, :test => 1}
  end

  it "should return table names in conditions for association joins" do
    @conditions[:foo] = {:bar => 1}
    @conditions[:test] = 1
    @rule.tableized_conditions.should == {:foos => {:bar => 1}, :test => 1}
  end

  it "should return no association joins if conditions is nil" do
    rule = CanCan::Rule.new(true, :read, Integer, nil, nil)
    rule.associations_hash.should == {}
  end
end
