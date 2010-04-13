Spec::Matchers.define :be_able_to do |action, subject|
  match do |model|
    model.can?(action, subject)
  end

  failure_message_for_should do |model|
    "expected to be able to #{action.inspect} #{subject.inspect}"
  end

  failure_message_for_should_not do |model|
    "expected not to be able to #{action.inspect} #{subject.inspect}"
  end
end
