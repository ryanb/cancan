require File.dirname(__FILE__) + '/../spec_helper'

describe CanCan::ControllerResource do
  before(:each) do
    @controller = Object.new
  end
  
  it "should determine model class by constantizing give name" do
    CanCan::ControllerResource.new(@controller, :ability).model_class.should == Ability
  end
  
  it "should fetch model through model class and assign it to the instance" do
    stub(Ability).find(123) { :some_ability }
    CanCan::ControllerResource.new(@controller, :ability).find(123)
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should fetch model through parent and assign it to the instance" do
    parent = Object.new
    stub(parent).model_instance.stub!.abilities.stub!.find(123) { :some_ability }
    CanCan::ControllerResource.new(@controller, :ability, parent).find(123)
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should build model through model class and assign it to the instance" do
    stub(Ability).new(123) { :some_ability }
    CanCan::ControllerResource.new(@controller, :ability).build(123)
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should build model through parent and assign it to the instance" do
    parent = Object.new
    stub(parent).model_instance.stub!.abilities.stub!.build(123) { :some_ability }
    CanCan::ControllerResource.new(@controller, :ability, parent).build(123)
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should not load resource if instance variable is already provided" do
    @controller.instance_variable_set(:@ability, :some_ability)
    CanCan::ControllerResource.new(@controller, :ability).find(123)
    @controller.instance_variable_get(:@ability).should == :some_ability
  end
  
  it "should use the model class option if provided" do
    stub(Person).find(123) { :some_resource }
    CanCan::ControllerResource.new(@controller, :ability, nil, :class => Person).find(123)
    @controller.instance_variable_get(:@ability).should == :some_resource
  end
end
