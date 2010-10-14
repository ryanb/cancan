require "spec_helper"
require 'mongoid'

class MongoidCategory
  include Mongoid::Document
  include CanCan::MongoidAdditions

  references_many :mongoid_projects
end

class MongoidProject
  include Mongoid::Document
  include CanCan::MongoidAdditions
  
  referenced_in :mongoid_category

  class << self
    protected

    def sanitize_sql(hash_cond)
      hash_cond
    end

    def sanitize_hash(hash)
      hash.map do |name, value|
        if Hash === value
          sanitize_hash(value).map{|cond| "#{name}.#{cond}"}
        else
          "#{name}=#{value}"
        end
      end.flatten
    end
  end
end

Mongoid.configure do |config|
  config.master = Mongo::Connection.new('127.0.0.1', 27017).db("workflow_on_mongoid")
end

describe CanCan::MongoidAdditions do
  before(:each) do
    @model_class = MongoidProject
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  after(:each) do
    Mongoid.master.collections.select do |collection|
      collection.name !~ /system/
    end.each(&:drop)    
  end

  it "should return [] when no ability is defined so no records are found" do
    @model_class.create :title  => 'Sir'
    @model_class.create :title  => 'Lord'
    @model_class.create :title  => 'Dude'
      
    @model_class.accessible_by(@ability, :read).should == []
  end
  
  describe "Mongoid::Criteria where clause Symbol extensions using MongoDB expressions" do
    it "should handle :field.in" do
      obj = @model_class.create :title  => 'Sir'
      @ability.can :read, @model_class, :title.in => ["Sir", "Madam"]
      @ability.can?(:read, obj).should == true
      
      obj2 = @model_class.create :title  => 'Lord'
      @ability.can?(:read, obj2).should == false
    end
    
    it "should handle :field.nin" do
      obj = @model_class.create :title  => 'Sir'
      @ability.can :read, @model_class, :title.nin => ["Lord", "Madam"]
      @ability.can?(:read, obj).should == true
      
      obj2 = @model_class.create :title  => 'Lord'
      @ability.can?(:read, obj2).should == false
    end
    
    it "should handle :field.size" do
      obj = @model_class.create :titles  => ['Palatin', 'Margrave']
      @ability.can :read, @model_class, :titles.size => 2
      @ability.can?(:read, obj).should == true
      
      obj2 = @model_class.create :titles  => ['Palatin', 'Margrave', 'Marquis']
      @ability.can?(:read, obj2).should == false
    end    

    it "should handle :field.exists" do
      obj = @model_class.create :titles  => ['Palatin', 'Margrave']
      @ability.can :read, @model_class, :titles.exists => true
      @ability.can?(:read, obj).should == true
      
      obj2 = @model_class.create
      @ability.can?(:read, obj2).should == false
    end
    
    it "should handle :field.gt" do
      obj = @model_class.create :age  => 50
      @ability.can :read, @model_class, :age.gt => 45
      @ability.can?(:read, obj).should == true
      
      obj2 = @model_class.create :age  => 40
      @ability.can?(:read, obj2).should == false
    end    
  end

  it "should call where with matching ability conditions" do
    @ability.can :read, @model_class, :foo => {:bar => 1}
    @model_class.accessible_by(@ability, :read).should == @model_class.where(:foos => { :bar => 1 })
  end

  it "should not allow to fetch records when ability with just block present" do
    @ability.can :read, @model_class do false end
    lambda {
      @model_class.accessible_by(@ability)
    }.should raise_error(CanCan::Error)
  end
end