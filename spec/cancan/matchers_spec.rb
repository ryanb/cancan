require "spec_helper"

describe "be_able_to" do
  it "delegates to can?" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123) { true }
    object.should be_able_to(:read, 123)
  end

  it "reports a nice failure message for should" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123) { false }
    expect do
      object.should be_able_to(:read, 123)
    end.should raise_error('expected to be able to :read 123')
  end

  it "reports a nice failure message for should not" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123) { true }
    expect do
      object.should_not be_able_to(:read, 123)
    end.should raise_error('expected not to be able to :read 123')
  end

  it "delegates additional arguments to can? and reports in failure message" do
    object = Object.new
    object.should_receive(:can?).with(:read, 123, 456) { false }
    expect do
      object.should be_able_to(:read, 123, 456)
    end.should raise_error('expected to be able to :read 123 456')
  end

  describe "multiple checks" do
    let(:object) { Object.new }

    it "delegates to can?" do
      object.should_receive(:can?).with(:read, 123) { true }
      object.should_receive(:can?).with(:update, 123) { true }
      object.should be_able_to([:read, :update], 123)
    end


    it "reports a nice failure message for should when all fail" do
      object.should_receive(:can?).with(:read, 123) { false }
      object.should_receive(:can?).with(:update, 123) { false }
      expect do
        object.should be_able_to([:read, :update], 123)
      end.should raise_error('expected to be able to [:read, :update] 123 but was not able to [:read, :update]')
    end

    it "reports a nice failure message for should when some fail" do
      object.should_receive(:can?).with(:read, 123) { false }
      object.should_receive(:can?).with(:update, 123) { true }
      expect do
        object.should be_able_to([:read, :update], 123)
      end.should raise_error('expected to be able to [:read, :update] 123 but was not able to [:read]')
    end

    it "reports a nice failure message for should not when all fail" do
      object.should_receive(:can?).with(:read, 123) { true }
      object.should_receive(:can?).with(:update, 123) { true }
      expect do
        object.should_not be_able_to([:read, :update], 123)
      end.should raise_error('expected not to be able to [:read, :update] 123 but was able to [:read, :update]')
    end

    it "reports a nice failure message for should not when some fail" do
      object.should_receive(:can?).with(:read, 123) { true }
      object.should_receive(:can?).with(:update, 123) { true }
      expect do
        object.should_not be_able_to([:read, :update], 123)
      end.should raise_error #('expected not to be able to [:read, :update] 123 but was able to [:read]')
    end

    it "delegates additional arguments to can? and reports in failure message" do
      object.should_receive(:can?).with(:read, 123, 456) { false }
      object.should_receive(:can?).with(:update, 123, 456) { false }
      expect do
        object.should be_able_to([:read, :update], 123, 456)
      end.should raise_error('expected to be able to [:read, :update] 123 456 but was not able to [:read, :update]')
    end
  end
end
