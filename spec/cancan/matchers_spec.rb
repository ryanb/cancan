require "spec_helper"

describe "be_able_to" do
  it "delegates to can?" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123).and_return(true)
    object.should be_able_to(:read, 123)
  end

  it "reports a nice failure message for should" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123).and_return(false)
    expect do
      object.should be_able_to(:read, 123)
    end.should raise_error('expected to be able to :read 123')
  end

  it "reports a nice failure message for should not" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123).and_return(true)
    expect do
      object.should_not be_able_to(:read, 123)
    end.should raise_error('expected not to be able to :read 123')
  end

  it "delegates additional arguments to can? and reports in failure message" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123, 456).and_return(false)
    expect do
      object.should be_able_to(:read, 123, 456)
    end.should raise_error('expected to be able to :read 123 456')
  end
end
