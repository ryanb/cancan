require "spec_helper"

# Most of Rule functionality is tested in Ability specs
describe CanCan::Rule do
  describe "#associations_hash" do
    before(:each) do
      @rules = {}
      @rule = CanCan::Rule.new(true, :read, Integer, @rules, nil)
    end

    it "should return no association joins if none exist" do
      @rule.associations_hash.should == {}
    end

    it "should return no association for joins if just attributes" do
      @rules[:foo] = :bar
      @rule.associations_hash.should == {}
    end

    it "should return single association for joins" do
      @rules[:foo] = {:bar => 1}
      @rule.associations_hash.should == {:foo => {}}
    end

    it "should return multiple associations for joins" do
      @rules[:foo] = {:bar => 1}
      @rules[:test] = {1 => 2}
      @rule.associations_hash.should == {:foo => {}, :test => {}}
    end

    it "should return nested associations for joins" do
      @rules[:foo] = {:bar => {1 => 2}}
      @rule.associations_hash.should == {:foo => {:bar => {}}}
    end

    it "should return no association joins if conditions is nil" do
      can = CanCan::Rule.new(true, :read, Integer, nil, nil)
      can.associations_hash.should == {}
    end
  end

  describe "#tableized_conditions" do
    with_model :landlord do
      table { |t| t.string :name }
      model do
        has_many :properties
        has_many :units, :through => :properties
      end
    end

    with_model :unit do
      table do |t|
        t.belongs_to :property
        t.integer :room_count
      end
      model { belongs_to :property }
    end

    with_model :property do
      table do |t|
        t.belongs_to :landlord
      end
      model do
        has_many :units
        belongs_to :landlord
      end
    end

    it "should return table names in conditions for association joins" do
      @rules = {}
      @rule = CanCan::Rule.new(true, :read, Property, @rules, nil)
      @rules[:units] = {:room_count => 1}
      @rules[:name] = 1
      @rule.tableized_conditions(Property).should == {unit.table_name => {:room_count => 1}, :name => 1}
    end

    it "should tableize correctly for complex permissions" do
      @rules = {}
      @rule = CanCan::Rule.new(true, :read, Landlord, @rules, nil)
      @rules[:properties] = {:units=>{:room_count=>2}}
      @rules[:name] = "Weasel"
      @rule.tableized_conditions(Landlord).should == {property.table_name => {unit.table_name => {:room_count=>2}}, :name => "Weasel"}
    end
  end
end
