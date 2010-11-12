require "spec_helper"

describe CanCan::ActiveRecordAdditions do
  before(:each) do
    @model_class = Class.new(Project)
    stub(@model_class).scoped { :scoped_stub }
    @model_class.send(:include, CanCan::ActiveRecordAdditions)
    @ability = Object.new
    @ability.extend(CanCan::Ability)
  end

  it "should call where('true=false') when no ability is defined so no records are found" do
    stub(@model_class).joins { true } # just so it responds to .joins as well
    stub(@model_class).where('true=false').stub!.joins(nil) { :no_match }
    @model_class.accessible_by(@ability, :read).should == :no_match
  end

  it "should call where with matching ability conditions" do
    @ability.can :read, @model_class, :foo => {:bar => 1}
    stub(@model_class).joins { true } # just so it responds to .joins as well
    stub(@model_class).where(:foos => { :bar => 1 }).stub!.joins([:foo]) { :found_records }
    @model_class.accessible_by(@ability, :read).should == :found_records
  end

  it "should default to :read ability and use scoped when where isn't available" do
    @ability.can :read, @model_class, :foo => {:bar => 1}
    stub(@model_class).scoped(:conditions => {:foos => {:bar => 1}}, :joins => [:foo]) { :found_records }
    @model_class.accessible_by(@ability).should == :found_records
  end

  it "should merge association joins and sanitize conditions" do
    @ability.can :read, @model_class, :foo => {:bar => 1}
    @ability.can :read, @model_class, :too => {:car => 1, :far => {:bar => 1}}

    condition_variants = [
        '(toos.fars.bar=1 AND toos.car=1) OR (foos.bar=1)', # faked sql sanitizer is stupid ;-)
        '(toos.car=1 AND toos.fars.bar=1) OR (foos.bar=1)'
    ]
    joins_variants = [
        [:foo, {:too => [:far]}],
        [{:too => [:far]}, :foo]
    ]

    condition_variants.each do |condition|
      joins_variants.each do |joins|
        stub(@model_class).scoped( :conditions => condition, :joins => joins ) { :found_records }
      end
    end
    # @ability.conditions(:read, @model_class).should == '(too.car=1 AND too.far.bar=1) OR (foo.bar=1)'
    # @ability.associations_hash(:read, @model_class).should == [{:too => [:far]}, :foo]
    @model_class.accessible_by(@ability).should == :found_records
  end

  it "should allow to define sql conditions by not hash" do
    @ability.can :read, @model_class, :foo => 1
    @ability.can :read, @model_class, ['bar = ?', 1]
    stub(@model_class).scoped( :conditions => '(bar = 1) OR (foo=1)', :joins => nil ) { :found_records }
    stub(@model_class).scoped{|*args| args.inspect}
    @model_class.accessible_by(@ability).should == :found_records
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
