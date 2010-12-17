require "spec_helper"

describe CanCan::ActiveRecordAdditions do
  with_model :foo do
    table do |t|
      t.integer :bar
      t.integer :baz
      t.belongs_to :model_class
    end
    model {}
  end

  with_model :model_class do
    table do |t|
      t.string :name
    end
    model do
      include CanCan::ActiveRecordAdditions
      has_many :foos, :foreign_key => 'model_class_id'
    end
  end

  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should call where('true=false') when no ability is defined so no records are found" do
    @model_class.accessible_by(@ability, :read).where_clauses.should include("('t'='f')")
  end

  it "should call where with matching ability conditions" do
    @ability.can :read, @model_class, :foos => {:bar => 1}
    @model_class.accessible_by(@ability, :read).join_sql.should include("INNER JOIN \"#{@foo.table_name}\"")
    @model_class.accessible_by(@ability, :read).where_clauses.should include("(\"#{@foo.table_name}\".\"bar\" = 1)")
  end

  it "should default to :read ability and use scoped when where isn't available" do
    @ability.can :read, @model_class, :name => "patty"
    @ability.can :update, @model_class, :name => "suzie"
    @model_class.accessible_by(@ability).where_clauses.should include("(\"#{@model_class.table_name}\".\"name\" = 'patty')")
    @model_class.accessible_by(@ability).where_clauses.should_not include("(\"#{@model_class.table_name}\".\"name\" = 'suzie')")
  end

  it "should merge association joins and sanitize conditions" do
    @ability.can :read, @model_class, :foos => {:bar => 1}
    @ability.can :read, @model_class, :foos => {:baz => 2}
    @model_class.accessible_by(@ability, :read).join_sql.should include("INNER JOIN \"#{@foo.table_name}\"")
    @model_class.accessible_by(@ability, :read).where_clauses.should include("((\"#{@foo.table_name}\".\"baz\" = 2) OR (\"#{@foo.table_name}\".\"bar\" = 1))")
  end

  it "should allow to define sql conditions by not hash" do
    @ability.can :read, @model_class, :name => 1
    @ability.can :read, @model_class, ['name = ?', 2]
    @model_class.accessible_by(@ability).where_clauses.should include("((name = 2) OR (\"#{@model_class.table_name}\".\"name\" = 1))")
  end

  it "should not allow to fetch records when ability with just block present" do
    @ability.can :read, @model_class do false end
    lambda {
      @model_class.accessible_by(@ability)
    }.should raise_error(CanCan::Error)
  end

  it "should not allow to check ability on object when nonhash sql ability definition without block present" do
    @ability.can :read, @model_class, ['bar = ?', 1]
    lambda {
      @ability.can? :read, @model_class.new
    }.should raise_error(CanCan::Error)
  end
end
