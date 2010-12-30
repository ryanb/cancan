if ENV["MODEL_ADAPTER"] == "mongoid"
  require "spec_helper"

  class MongoidCategory
    include Mongoid::Document
    include CanCan::ModelAdditions

    references_many :mongoid_projects
  end

  class MongoidProject
    include Mongoid::Document
    include CanCan::ModelAdditions

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
    config.master = Mongo::Connection.new('127.0.0.1', 27017).db("cancan_mongoid_spec")
  end

  describe CanCan::ModelAdapters::MongoidAdapter do
    context "Mongoid not defined" do
      before(:all) do
        @mongoid_class = Object.send(:remove_const, :Mongoid)
      end

      after(:all) do
        Object.const_set(:Mongoid, @mongoid_class)
      end

      it "should not raise an error for ActiveRecord models" do
        @model_class = Class.new(Project)
        stub(@model_class).scoped { :scoped_stub }
        @ability = Object.new
        @ability.extend(CanCan::Ability)

        @ability.can :read, @model_class
        lambda {
          @ability.can? :read, @model_class.new
        }.should_not raise_error
      end
    end

    context "Mongoid defined" do
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

      it "should be for only Mongoid classes" do
        CanCan::ModelAdapters::MongoidAdapter.should_not be_for_class(Object)
        CanCan::ModelAdapters::MongoidAdapter.should be_for_class(@model_class)
        CanCan::ModelAdapters::AbstractAdapter.adapter_class(@model_class).should == CanCan::ModelAdapters::MongoidAdapter
      end

      it "should compare properties on mongoid documents with the conditions hash" do
        model = @model_class.new
        @ability.can :read, @model_class, :id => model.id
        @ability.should be_able_to :read, model
      end

      it "should return [] when no ability is defined so no records are found" do
        @model_class.create :title  => 'Sir'
        @model_class.create :title  => 'Lord'
        @model_class.create :title  => 'Dude'

        @model_class.accessible_by(@ability, :read).entries.should == []
      end

      it "should return the correct records based on the defined ability" do
        @ability.can :read, @model_class, :title => "Sir"
        sir   = @model_class.create :title  => 'Sir'
        lord  = @model_class.create :title  => 'Lord'
        dude  = @model_class.create :title  => 'Dude'

        @model_class.accessible_by(@ability, :read).should == [sir]
      end

      it "should return everything when the defined ability is manage all" do
        @ability.can :manage, :all
        sir   = @model_class.create :title  => 'Sir'
        lord  = @model_class.create :title  => 'Lord'
        dude  = @model_class.create :title  => 'Dude'

        @model_class.accessible_by(@ability, :read).entries.should == [sir, lord, dude]
      end


      describe "Mongoid::Criteria where clause Symbol extensions using MongoDB expressions" do
        it "should handle :field.in" do
          obj = @model_class.create :title  => 'Sir'
          @ability.can :read, @model_class, :title.in => ["Sir", "Madam"]
          @ability.can?(:read, obj).should == true
          @model_class.accessible_by(@ability, :read).should == [obj]

          obj2 = @model_class.create :title  => 'Lord'
          @ability.can?(:read, obj2).should == false
        end

        describe "activates only when there are Criteria in the hash" do
          it "Calls where on the model class when there are criteria" do
            obj = @model_class.create :title  => 'Bird'
            @conditions = {:title.nin => ["Fork", "Spoon"]}
            mock(@model_class).where(@conditions) {[obj]}
            @ability.can :read, @model_class, @conditions
            @ability.should be_able_to(:read, obj)
          end
          it "Calls the base version if there are no mongoid criteria" do
            obj = @model_class.new :title  => 'Bird'
            @conditions = {:id => obj.id}
            @ability.can :read, @model_class, @conditions
            @ability.should be_able_to(:read, obj)
          end
        end

        it "should handle :field.nin" do
          obj = @model_class.create :title  => 'Sir'
          @ability.can :read, @model_class, :title.nin => ["Lord", "Madam"]
          @ability.can?(:read, obj).should == true
          @model_class.accessible_by(@ability, :read).should == [obj]

          obj2 = @model_class.create :title  => 'Lord'
          @ability.can?(:read, obj2).should == false
        end

        it "should handle :field.size" do
          obj = @model_class.create :titles  => ['Palatin', 'Margrave']
          @ability.can :read, @model_class, :titles.size => 2
          @ability.can?(:read, obj).should == true
          @model_class.accessible_by(@ability, :read).should == [obj]

          obj2 = @model_class.create :titles  => ['Palatin', 'Margrave', 'Marquis']
          @ability.can?(:read, obj2).should == false
        end

        it "should handle :field.exists" do
          obj = @model_class.create :titles  => ['Palatin', 'Margrave']
          @ability.can :read, @model_class, :titles.exists => true
          @ability.can?(:read, obj).should == true
          @model_class.accessible_by(@ability, :read).should == [obj]

          obj2 = @model_class.create
          @ability.can?(:read, obj2).should == false
        end

        it "should handle :field.gt" do
          obj = @model_class.create :age  => 50
          @ability.can :read, @model_class, :age.gt => 45
          @ability.can?(:read, obj).should == true
          @model_class.accessible_by(@ability, :read).should == [obj]

          obj2 = @model_class.create :age  => 40
          @ability.can?(:read, obj2).should == false
        end
      end

      it "should call where with matching ability conditions" do
        obj = @model_class.create :foo => {:bar => 1}
        @ability.can :read, @model_class, :foo => {:bar => 1}
        @model_class.accessible_by(@ability, :read).entries.first.should == obj
      end

      it "should not allow to fetch records when ability with just block present" do
        @ability.can :read, @model_class do false end
        lambda {
          @model_class.accessible_by(@ability)
        }.should raise_error(CanCan::Error)
      end
    end
  end
end
