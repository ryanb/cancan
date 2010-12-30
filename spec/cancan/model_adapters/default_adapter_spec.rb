require "spec_helper"

describe CanCan::ModelAdapters::DefaultAdapter do
  it "should be default for generic classes" do
    CanCan::ModelAdapters::AbstractAdapter.adapter_class(Object).should == CanCan::ModelAdapters::DefaultAdapter
  end
end
