if ENV["MODEL_ADAPTER"] == "mongo_mapper"
  require "spec_helper"

  MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
  MongoMapper.database = "cancan_mongomapper_spec"

  class MongoMapperProject
    include MongoMapper::Document
  end

  describe CanCan::ModelAdapters::MongoMapperAdapter, :focus => true do
    context "MongoMapper defined" do
      before(:each) do
        @ability = Object.new
        @ability.extend(CanCan::Ability)
      end

      after(:each) do
        MongoMapperProject.destroy_all
      end

      it "should be for only MongoMapper classes" do
        CanCan::ModelAdapters::MongoMapperAdapter.should_not be_for_class(Object)
        CanCan::ModelAdapters::MongoMapperAdapter.should be_for_class(MongoMapperProject)
        CanCan::ModelAdapters::AbstractAdapter.adapter_class(MongoMapperProject).should == CanCan::ModelAdapters::MongoMapperAdapter
      end

      it "should find record" do
        project = MongoMapperProject.create
        CanCan::ModelAdapters::MongoMapperAdapter.find(MongoMapperProject, project.id).should == project
      end

      it "should compare properties on mongomapper documents with the conditions hash" do
        model = MongoMapperProject.new
        @ability.can :read, MongoMapperProject, :id => model.id
        @ability.should be_able_to(:read, model)
      end

      it "should be able to read hashes when field is array" do
        one_to_three = MongoMapperProject.create(:numbers => ['one', 'two', 'three'])
        two_to_five  = MongoMapperProject.create(:numbers => ['two', 'three', 'four', 'five'])

        @ability.can :foo, MongoMapperProject, :numbers => 'one'
        @ability.should be_able_to(:foo, one_to_three)
        @ability.should_not be_able_to(:foo, two_to_five)
      end

      it "should return [] when no ability is defined so no records are found" do
        MongoMapperProject.create
        MongoMapperProject.create
        MongoMapperProject.create

        MongoMapperProject.accessible_by(@ability, :read).entries.should == []
      end

      it "should return the correct records based on the defined ability" do
        @ability.can :read, MongoMapperProject, :title => "Sir"
        sir   = MongoMapperProject.create(:title => 'Sir')
        lord  = MongoMapperProject.create(:title => 'Lord')
        dude  = MongoMapperProject.create(:title => 'Dude')

        MongoMapperProject.accessible_by(@ability, :read).entries.should == [sir]
      end

      it "should be able to mix empty conditions and hashes" do
        @ability.can :read, MongoMapperProject
        @ability.can :read, MongoMapperProject, :title => 'Sir'
        sir  = MongoMapperProject.create(:title => 'Sir')
        lord = MongoMapperProject.create(:title => 'Lord')

        MongoMapperProject.accessible_by(@ability, :read).count.should == 2
      end

      it "should return everything when the defined ability is manage all" do
        @ability.can :manage, :all
        sir   = MongoMapperProject.create(:title => 'Sir')
        lord  = MongoMapperProject.create(:title => 'Lord')
        dude  = MongoMapperProject.create(:title => 'Dude')

        MongoMapperProject.accessible_by(@ability, :read).entries.should == [sir, lord, dude]
      end

      it "should call where with matching ability conditions" do
        obj = MongoMapperProject.create(:foo => {:bar => 1})
        @ability.can :read, MongoMapperProject, :foo => {:bar => 1}
        MongoMapperProject.accessible_by(@ability, :read).entries.first.should == obj
      end

      it "should exclude from the result if set to cannot" do
        obj = MongoMapperProject.create(:bar => 1)
        obj2 = MongoMapperProject.create(:bar => 2)
        @ability.can :read, MongoMapperProject
        @ability.cannot :read, MongoMapperProject, :bar => 2
        MongoMapperProject.accessible_by(@ability, :read).entries.should == [obj]
      end

      it "should combine the rules" do
        obj = MongoMapperProject.create(:bar => 1)
        obj2 = MongoMapperProject.create(:bar => 2)
        obj3 = MongoMapperProject.create(:bar => 3)
        @ability.can :read, MongoMapperProject, :bar => 1
        @ability.can :read, MongoMapperProject, :bar => 2
        MongoMapperProject.accessible_by(@ability, :read).entries.should =~ [obj, obj2]
      end

    end
  end
end
