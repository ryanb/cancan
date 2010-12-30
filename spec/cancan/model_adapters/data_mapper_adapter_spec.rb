if ENV["MODEL_ADAPTER"] == "data_mapper"
  require "spec_helper"

  describe CanCan::ModelAdapters::DataMapperAdapter do
    before(:each) do
      @model_class = Class.new
      @model_class.class_eval do
        include DataMapper::Resource
      end
      stub(@model_class).all(:conditions => ['true=false']) { 'no-match:' }

      @ability = Object.new
      @ability.extend(CanCan::Ability)
    end

    it "should be for only data mapper classes" do
      CanCan::ModelAdapters::DataMapperAdapter.should_not be_for_class(Object)
      CanCan::ModelAdapters::DataMapperAdapter.should be_for_class(@model_class)
      CanCan::ModelAdapters::AbstractAdapter.adapter_class(@model_class).should == CanCan::ModelAdapters::DataMapperAdapter
    end

    it "should return no records when no ability is defined so no records are found" do
      @model_class.accessible_by(@ability, :read).should == 'no-match:'
    end

    it "should call all with matching ability conditions" do
      @ability.can :read, @model_class, :foo => {:bar => 1}
      stub(@model_class).all(:conditions => {:foo => {:bar => 1}}) { 'found-records:' }
      @model_class.accessible_by(@ability, :read).should == 'no-match:found-records:'
    end

    it "should merge association joins and sanitize conditions" do
      @ability.can :read, @model_class, :foo => {:bar => 1}
      @ability.can :read, @model_class, :too => {:car => 1, :far => {:bar => 1}}

      stub(@model_class).all(:conditions => {:foo => {:bar => 1}}) { 'foo:' }
      stub(@model_class).all(:conditions => {:too => {:car => 1, :far => {:bar => 1}}}) { 'too:' }

      @model_class.accessible_by(@ability).should == 'no-match:too:foo:'
    end

    it "should allow to define sql conditions by not hash" do
      @ability.can :read, @model_class, :foo => 1
      @ability.can :read, @model_class, ['bar = ?', 1]

      stub(@model_class).all(:conditions => {:foo => 1}) { 'foo:' }
      stub(@model_class).all(:conditions => ['bar = ?', 1]) { 'bar:' }

      @model_class.accessible_by(@ability).should == 'no-match:bar:foo:'
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
end
