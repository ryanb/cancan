require "spec_helper"

describe "be_able_to" do
  it "delegates to can?" do
    object = Object.new
    mock(object).can?(:read, 123) { true }
    object.should be_able_to(:read, 123)
  end

  it "reports a nice failure message for should" do
    object = Object.new
    mock(object).can?(:read, 123) { false }
    expect do
      object.should be_able_to(:read, 123)
    end.should raise_error('expected to be able to :read 123')
  end

  it "reports a nice failure message for should not" do
    object = Object.new
    mock(object).can?(:read, 123) { true }
    expect do
      object.should_not be_able_to(:read, 123)
    end.should raise_error('expected not to be able to :read 123')
  end
end
