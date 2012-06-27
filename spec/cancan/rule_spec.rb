require "spec_helper"
require "ostruct" # for OpenStruct below

# Most of Rule functionality is tested in Ability specs
describe CanCan::Rule do
  before(:each) do
    @conditions = {}
    @rule = CanCan::Rule.new(true, :read, :integers, @conditions)
  end

  it "returns no association joins if none exist" do
    @rule.associations_hash.should == {}
  end

  it "returns no association for joins if just attributes" do
    @conditions[:foo] = :bar
    @rule.associations_hash.should == {}
  end

  it "returns single association for joins" do
    @conditions[:foo] = {:bar => 1}
    @rule.associations_hash.should == {:foo => {}}
  end

  it "returns multiple associations for joins" do
    @conditions[:foo] = {:bar => 1}
    @conditions[:test] = {1 => 2}
    @rule.associations_hash.should == {:foo => {}, :test => {}}
  end

  it "returns nested associations for joins" do
    @conditions[:foo] = {:bar => {1 => 2}}
    @rule.associations_hash.should == {:foo => {:bar => {}}}
  end

  it "returns no association joins if conditions is nil" do
    rule = CanCan::Rule.new(true, :read, :integers)
    rule.associations_hash.should == {}
  end

  it "has higher specificity for attributes/conditions" do
    CanCan::Rule.new(true, :read, :integers).specificity.should eq(1)
    CanCan::Rule.new(true, :read, :integers, :foo => :bar).specificity.should eq(2)
    CanCan::Rule.new(true, :read, :integers, :foo).specificity.should eq(2)
    CanCan::Rule.new(false, :read, :integers).specificity.should eq(3)
    CanCan::Rule.new(false, :read, :integers, :foo => :bar).specificity.should eq(4)
    CanCan::Rule.new(false, :read, :integers, :foo).specificity.should eq(4)
  end

  it "should not be mergeable if conditions are not simple hashes" do
    meta_where = OpenStruct.new(:name => 'metawhere', :column => 'test')
    @conditions[meta_where] = :bar
    @rule.should be_unmergeable
  end
end
