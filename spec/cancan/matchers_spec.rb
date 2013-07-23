require "spec_helper"

describe "be_able_to" do
  it "delegates to can?" do
    expect(object = double).to receive(:can?).with(:read, 123) { true }
    expect(object).to be_able_to(:read, 123)
  end

  it "reports a nice failure message for should" do
    expect(object = double).to receive(:can?).with(:read, 123) { false }
    expect {
      expect(object).to be_able_to(:read, 123)
    }.to raise_error('expected to be able to :read 123')
  end

  it "reports a nice failure message for should not" do
    expect(object = double).to receive(:can?).with(:read, 123) { true }
    expect {
      expect(object).to_not be_able_to(:read, 123)
    }.to raise_error('expected not to be able to :read 123')
  end

  it "delegates additional arguments to can? and reports in failure message" do
    expect(object = double).to receive(:can?).with(:read, 123, 456) { false }
    expect {
      expect(object).to be_able_to(:read, 123, 456)
    }.to raise_error('expected to be able to :read 123 456')
  end
end
