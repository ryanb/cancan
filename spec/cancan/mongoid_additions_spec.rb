require "spec_helper"
require 'mongoid'

class MongoidCategory
  include Mongoid::Document
  references_many :mongoid_projects
end

class MongoidProject
  include Mongoid::Document
  
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
    @model_class = Class.new(MongoidProject)
    stub(@model_class).scoped { :scoped_stub }
    @model_class.send(:include, CanCan::MongoidAdditions)
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  after(:each) do
    Mongoid.master.collections.select do |collection|
      collection.name !~ /system/
    end.each(&:drop)    
  end

  it "should return [] when no ability is defined so no records are found" do
    @model_class.accessible_by(@ability, :read).should == []
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