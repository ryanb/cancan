require "spec_helper"

describe CanCan::CanDefinition do
  before(:each) do
    @conditions = {}
    @can = CanCan::CanDefinition.new(true, :read, Integer, @conditions, nil)
  end

  it "should return no association joins if none exist" do
    @can.association_joins.should be_nil
  end

  it "should return no association for joins if just attributes" do
    @conditions[:foo] = :bar
    @can.association_joins.should be_nil
  end

  it "should return single association for joins" do
    @conditions[:foo] = {:bar => 1}
    @can.association_joins.should == [:foo]
  end

  it "should return multiple associations for joins" do
    @conditions[:foo] = {:bar => 1}
    @conditions[:test] = {1 => 2}
    @can.association_joins.map(&:to_s).sort.should == [:foo, :test].map(&:to_s).sort
  end

  it "should return nested associations for joins" do
    @conditions[:foo] = {:bar => {1 => 2}}
    @can.association_joins.should == [{:foo => [:bar]}]
  end

  it "should return table names in conditions for association joins" do
    @conditions[:foo] = {:bar => 1}
    @conditions[:test] = 1
    @can.conditions(:tableize => true).should == { :foos => { :bar => 1}, :test => 1 }
  end

  it "should return no association joins if conditions is nil" do
    can = CanCan::CanDefinition.new(true, :read, Integer, nil, nil)
    can.association_joins.should be_nil
  end
end
