require "spec_helper"
require "ostruct" # for OpenStruct below

# Most of Rule functionality is tested in Ability specs
describe CanCan::Rule do
  before(:each) do
    @conditions = {}
    @rule = CanCan::Rule.new(true, :read, Integer, @conditions, nil)
  end

  it "should return no association joins if none exist" do
    expect(@rule.associations_hash).to eq({})
  end

  it "should return no association for joins if just attributes" do
    @conditions[:foo] = :bar
    expect(@rule.associations_hash).to eq({})
  end

  it "should return single association for joins" do
    @conditions[:foo] = {:bar => 1}
    expect(@rule.associations_hash).to eq({:foo => {}})
  end

  it "should return multiple associations for joins" do
    @conditions[:foo] = {:bar => 1}
    @conditions[:test] = {1 => 2}
    expect(@rule.associations_hash).to eq({:foo => {}, :test => {}})
  end

  it "should return nested associations for joins" do
    @conditions[:foo] = {:bar => {1 => 2}}
    expect(@rule.associations_hash).to eq({:foo => {:bar => {}}})
  end

  it "should return no association joins if conditions is nil" do
    rule = CanCan::Rule.new(true, :read, Integer, nil, nil)
    expect(rule.associations_hash).to eq({})
  end

  it "should not be mergeable if conditions are not simple hashes" do
    meta_where = OpenStruct.new(:name => 'metawhere', :column => 'test')
    @conditions[meta_where] = :bar

    expect(@rule).to be_unmergeable
  end

  it "should be mergeable if conditions is an empty hash" do
    @conditions = {}
    expect(@rule).to_not be_unmergeable
  end
end
