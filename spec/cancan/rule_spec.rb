require "spec_helper"
require "ostruct" # for OpenStruct below

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

  it "should return no association joins if conditions is nil" do
    rule = CanCan::Rule.new(true, :read, Integer, nil, nil)
    rule.associations_hash.should == {}
  end

  it "should not be mergeable if conditions are not simple hashes" do
    meta_where = OpenStruct.new(:name => 'metawhere', :column => 'test')
    @conditions[meta_where] = :bar

    @rule.should be_unmergeable
  end

  it "should be able to accept the name of a mapped method" do
    rule = CanCan::Rule.new(true, :read, Integer, nil, :evaluate)
    rule.instance_variable_get(:@block).should be nil
    rule.instance_variable_get(:@method).should be :evaluate

    rule = CanCan::Rule.new(true, :read, Integer, nil, proc{})
    rule.instance_variable_get(:@block).should_not be nil
    rule.instance_variable_get(:@method).should be nil
  end
end
