if ENV["MODEL_ADAPTER"] == "mongoid"
  require "spec_helper"

  class MongoidCategory
    include Mongoid::Document
    references_many :mongoid_projects
  end

  class MongoidProject
    include Mongoid::Document
    referenced_in :mongoid_category
  end

  Mongoid.configure do |config|
    config.master = Mongo::Connection.new('127.0.0.1', 27017).db("cancan_mongoid_spec")
  end

  describe CanCan::ModelAdapters::MongoidAdapter do
    context "Mongoid defined" do
      before(:each) do
        @ability = Object.new
        @ability.extend(CanCan::Ability)
      end

      after(:each) do
        Mongoid.master.collections.select do |collection|
          collection.name !~ /system/
        end.each(&:drop)
      end

      it "is for only Mongoid classes" do
        CanCan::ModelAdapters::MongoidAdapter.should_not be_for_class(Object)
        CanCan::ModelAdapters::MongoidAdapter.should be_for_class(MongoidProject)
        CanCan::ModelAdapters::AbstractAdapter.adapter_class(MongoidProject).should == CanCan::ModelAdapters::MongoidAdapter
      end

      it "finds record" do
        project = MongoidProject.create
        CanCan::ModelAdapters::MongoidAdapter.find(MongoidProject, project.id).should == project
      end

      it "compares properties on mongoid documents with the conditions hash" do
        model = MongoidProject.new
        @ability.can :read, :mongoid_projects, :id => model.id
        @ability.should be_able_to(:read, model)
      end

      it "is able to read hashes when field is array" do
        one_to_three = MongoidProject.create(:numbers => ['one', 'two', 'three'])
        two_to_five  = MongoidProject.create(:numbers => ['two', 'three', 'four', 'five'])

        @ability.can :foo, :mongoid_projects, :numbers => 'one'
        @ability.should be_able_to(:foo, one_to_three)
        @ability.should_not be_able_to(:foo, two_to_five)
      end

      it "returns [] when no ability is defined so no records are found" do
        MongoidProject.create(:title => 'Sir')
        MongoidProject.create(:title => 'Lord')
        MongoidProject.create(:title => 'Dude')

        MongoidProject.accessible_by(@ability, :read).entries.should == []
      end

      it "returns the correct records based on the defined ability" do
        @ability.can :read, :mongoid_projects, :title => "Sir"
        sir   = MongoidProject.create(:title => 'Sir')
        lord  = MongoidProject.create(:title => 'Lord')
        dude  = MongoidProject.create(:title => 'Dude')

        MongoidProject.accessible_by(@ability, :read).entries.should == [sir]
      end

      it "returns the correct records when a mix of can and cannot rules in defined ability" do
        pending "TODO figure out why this isn't working"
        @ability.can :manage, :mongoid_projects, :title => 'Sir'
        @ability.cannot :destroy, :mongoid_projects

        sir   = MongoidProject.create(:title => 'Sir')
        lord  = MongoidProject.create(:title => 'Lord')
        dude  = MongoidProject.create(:title => 'Dude')

        MongoidProject.accessible_by(@ability, :destroy).entries.should == [sir]
      end

      it "takes presedence over rule defined without a condition" do
        @ability.can :read, :mongoid_projects
        @ability.can :read, :mongoid_projects, :title => 'Sir'
        sir  = MongoidProject.create(:title => 'Sir')
        lord = MongoidProject.create(:title => 'Lord')

        MongoidProject.accessible_by(@ability, :read).entries.should == [sir]
      end

      it "returns everything when the defined ability is access all" do
        @ability.can :access, :all
        sir   = MongoidProject.create(:title => 'Sir')
        lord  = MongoidProject.create(:title => 'Lord')
        dude  = MongoidProject.create(:title => 'Dude')

        MongoidProject.accessible_by(@ability, :read).entries.should == [sir, lord, dude]
      end

      it "allows a scope for conditions" do
        @ability.can :read, :mongoid_projects, MongoidProject.where(:title => 'Sir')
        sir   = MongoidProject.create(:title => 'Sir')
        lord  = MongoidProject.create(:title => 'Lord')
        dude  = MongoidProject.create(:title => 'Dude')

        MongoidProject.accessible_by(@ability, :read).entries.should == [sir]
      end

      describe "Mongoid::Criteria where clause Symbol extensions using MongoDB expressions" do
        it "handles :field.in" do
          obj = MongoidProject.create(:title => 'Sir')
          @ability.can :read, :mongoid_projects, :title.in => ["Sir", "Madam"]
          @ability.can?(:read, obj).should == true
          MongoidProject.accessible_by(@ability, :read).should == [obj]

          obj2 = MongoidProject.create(:title => 'Lord')
          @ability.can?(:read, obj2).should == false
        end

        describe "activates only when there are Criteria in the hash" do
          it "Calls where on the model class when there are criteria" do
            obj = MongoidProject.create(:title => 'Bird')
            @conditions = {:title.nin => ["Fork", "Spoon"]}

            @ability.can :read, :mongoid_projects, @conditions
            @ability.should be_able_to(:read, obj)
          end
          it "Calls the base version if there are no mongoid criteria" do
            obj = MongoidProject.new(:title => 'Bird')
            @conditions = {:id => obj.id}
            @ability.can :read, :mongoid_projects, @conditions
            @ability.should be_able_to(:read, obj)
          end
        end

        it "handles :field.nin" do
          obj = MongoidProject.create(:title => 'Sir')
          @ability.can :read, :mongoid_projects, :title.nin => ["Lord", "Madam"]
          @ability.can?(:read, obj).should == true
          MongoidProject.accessible_by(@ability, :read).should == [obj]

          obj2 = MongoidProject.create(:title => 'Lord')
          @ability.can?(:read, obj2).should == false
        end

        it "handles :field.size" do
          obj = MongoidProject.create(:titles => ['Palatin', 'Margrave'])
          @ability.can :read, :mongoid_projects, :titles.size => 2
          @ability.can?(:read, obj).should == true
          MongoidProject.accessible_by(@ability, :read).should == [obj]

          obj2 = MongoidProject.create(:titles => ['Palatin', 'Margrave', 'Marquis'])
          @ability.can?(:read, obj2).should == false
        end

        it "handles :field.exists" do
          obj = MongoidProject.create(:titles => ['Palatin', 'Margrave'])
          @ability.can :read, :mongoid_projects, :titles.exists => true
          @ability.can?(:read, obj).should == true
          MongoidProject.accessible_by(@ability, :read).should == [obj]

          obj2 = MongoidProject.create
          @ability.can?(:read, obj2).should == false
        end

        it "handles :field.gt" do
          obj = MongoidProject.create(:age => 50)
          @ability.can :read, :mongoid_projects, :age.gt => 45
          @ability.can?(:read, obj).should == true
          MongoidProject.accessible_by(@ability, :read).should == [obj]

          obj2 = MongoidProject.create(:age => 40)
          @ability.can?(:read, obj2).should == false
        end

        it "handles instance not saved to database" do
          obj = MongoidProject.new(:title => 'Sir')
          @ability.can :read, :mongoid_projects, :title.in => ["Sir", "Madam"]
          @ability.can?(:read, obj).should == true

          # accessible_by only returns saved records
          MongoidProject.accessible_by(@ability, :read).entries.should == []

          obj2 = MongoidProject.new(:title => 'Lord')
          @ability.can?(:read, obj2).should == false
        end
      end

      it "calls where with matching ability conditions" do
        obj = MongoidProject.create(:foo => {:bar => 1})
        @ability.can :read, :mongoid_projects, :foo => {:bar => 1}
        MongoidProject.accessible_by(@ability, :read).entries.first.should == obj
      end

      it "excludes from the result if set to cannot" do
        obj = MongoidProject.create(:bar => 1)
        obj2 = MongoidProject.create(:bar => 2)
        @ability.can :read, :mongoid_projects
        @ability.cannot :read, :mongoid_projects, :bar => 2
        MongoidProject.accessible_by(@ability, :read).entries.should == [obj]
      end

      it "combines the rules" do
        obj = MongoidProject.create(:bar => 1)
        obj2 = MongoidProject.create(:bar => 2)
        obj3 = MongoidProject.create(:bar => 3)
        @ability.can :read, :mongoid_projects, :bar => 1
        @ability.can :read, :mongoid_projects, :bar => 2
        MongoidProject.accessible_by(@ability, :read).entries.should =~ [obj, obj2]
      end

      it "does not allow to fetch records when ability with just block present" do
        @ability.can :read, :mongoid_projects do
          false
        end
        lambda {
          MongoidProject.accessible_by(@ability)
        }.should raise_error(CanCan::Error)
      end
    end
  end
end
