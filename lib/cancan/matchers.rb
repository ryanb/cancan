rspec_module = defined?(RSpec::Core) ? 'RSpec' : 'Spec'  # for RSpec 1 compatability
Kernel.const_get(rspec_module)::Matchers.define :be_able_to do |*args|

  @actions = Array(args.first)
  @errors = []

  def ability_can?(ability, *args)
    extra_args = args[1..-1]
    @actions.each do |action|
      @errors << action unless ability.can?(action, *extra_args)
    end
  end

  match do |ability|
    ability_can?(ability, *args)
    @errors.empty?
  end

  match_for_should_not do |ability|
    ability_can?(ability, *args)
    @errors.any?
  end

  failure_message_for_should do |ability|
    message = "expected to be able to #{args.map(&:inspect).join(" ")}"
    message << " but was not able to #{@errors.inspect}" if args.first.kind_of?(Array)
    message
  end

  failure_message_for_should_not do |ability|
    message = "expected not to be able to #{args.map(&:inspect).join(" ")}"
    message << " but was able to #{(@actions - @errors).inspect}" if args.first.kind_of?(Array)
    message
  end
end
