Spec::Matchers.define :be_able_to do |*args|
  match do |ability|
    ability.can?(*args)
  end

  failure_message_for_should do |ability|
    "expected to be able to #{args.map(&:inspect).join(" ")}"
  end

  failure_message_for_should_not do |ability|
    "expected not to be able to #{args.map(&:inspect).join(" ")}"
  end
end
