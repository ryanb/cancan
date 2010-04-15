Spec::Matchers.define :be_able_to do |*args|
  match do |model|
    model.can?(*args)
  end

  failure_message_for_should do |model|
    "expected to be able to #{args.map(&:inspect).join(" ")}"
  end

  failure_message_for_should_not do |model|
    "expected not to be able to #{args.map(&:inspect).join(" ")}"
  end
end
