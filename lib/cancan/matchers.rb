rspec_module = Kernel.const_get(defined?(RSpec::Core) ? 'RSpec' : 'Spec')  # for RSpec 1 compatability
rspec_module::Matchers.define :be_able_to do |*args|
  match do |ability|
    ability.can?(*args)
  end

  if rspec_module::Version && rspec_module::Version::STRING =~ /^3\./
    failure_message do |ability|
       "expected to be able to #{args.map(&:inspect).join(" ")}"
    end

    failure_message_when_negated do |ability|
      "expected not to be able to #{args.map(&:inspect).join(" ")}"
    end
  else
    failure_message_for_should do |ability|
      "expected to be able to #{args.map(&:inspect).join(" ")}"
    end

    failure_message_for_should_not do |ability|
      "expected not to be able to #{args.map(&:inspect).join(" ")}"
    end
  end
end
