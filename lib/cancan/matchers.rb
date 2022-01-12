rspec_module = defined?(RSpec::Core) ? 'RSpec' : 'Spec'  # for RSpec 1 compatability
Kernel.const_get(rspec_module)::Matchers.define :be_able_to do |*args|
  match do |ability|
    ability.can?(*args)
  end

  failure_message do |ability|
    "expected to be able to #{args.map(&:inspect).join(" ")}"
  end

  failure_message_when_negated do |ability|
    "expected not to be able to #{args.map(&:inspect).join(" ")}"
  end
end
