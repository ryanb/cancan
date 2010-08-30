module CanCan
  # This class is used internally and should only be called through Ability.
  # it holds the information about a "can" call made on Ability and provides
  # helpful methods to determine permission checking and conditions hash generation.
  class CanDefinition # :nodoc:
    attr_reader :base_behavior, :actions
    attr_writer :expanded_actions

    # The first argument when initializing is the base_behavior which is a true/false
    # value. True for "can" and false for "cannot". The next two arguments are the action
    # and subject respectively (such as :read, @project). The third argument is a hash
    # of conditions and the last one is the block passed to the "can" call.
    def initialize(base_behavior, action, subject, conditions, block)
      @base_behavior = base_behavior
      @actions = [action].flatten
      @subjects = [subject].flatten
      @conditions = conditions || {}
      @block = block
    end

    # Matches both the subject and action, not necessarily the conditions
    def relevant?(action, subject)
      matches_action?(action) && matches_subject?(subject)
    end

    # Matches the block or conditions hash
    def matches_conditions?(action, subject, extra_args)
      if @block
        call_block(action, subject, extra_args)
      elsif @conditions.kind_of?(Hash) && subject.class != Class
        matches_conditions_hash?(subject)
      else
        @base_behavior
      end
    end

    def tableized_conditions(conditions = @conditions)
      conditions.inject({}) do |result_hash, (name, value)|
        if value.kind_of? Hash
          name = name.to_s.tableize.to_sym
          value = tableized_conditions(value)
        end
        result_hash[name] = value
        result_hash
      end
    end

    def only_block?
      conditions_empty? && !@block.nil?
    end

    def conditions_empty?
      @conditions == {} || @conditions.nil?
    end

    def associations_hash(conditions = @conditions)
      hash = {}
      conditions.map do |name, value|
        hash[name] = associations_hash(value) if value.kind_of? Hash
      end
      hash
    end

    private

    def matches_action?(action)
      @expanded_actions.include?(:manage) || @expanded_actions.include?(action)
    end

    def matches_subject?(subject)
      @subjects.include?(:all) || @subjects.include?(subject) || matches_subject_class?(subject)
    end

    def matches_subject_class?(subject)
      @subjects.any? { |sub| sub.kind_of?(Class) && (subject.kind_of?(sub) || subject.kind_of?(Class) && subject.ancestors.include?(sub)) }
    end

    def matches_conditions_hash?(subject, conditions = @conditions)
      conditions.all? do |name, value|
        attribute = subject.send(name)
        if value.kind_of?(Hash)
          if attribute.kind_of? Array
            attribute.any? { |element| matches_conditions_hash? element, value }
          else
            matches_conditions_hash? attribute, value
          end
        elsif value.kind_of?(Array) || value.kind_of?(Range)
          value.include? attribute
        else
          attribute == value
        end
      end
    end

    def call_block(action, subject, extra_args)
      block_args = []
      block_args << action if @expanded_actions.include?(:manage)
      block_args << (subject.class == Class ? subject : subject.class) if @subjects.include?(:all)
      block_args << (subject.class == Class ? nil : subject)
      block_args += extra_args
      @block.call(*block_args)
    end
  end
end
