module CanCan
  # This class is used internally and should only be called through Ability.
  # it holds the information about a "can" call made on Ability and provides
  # helpful methods to determine permission checking and conditions hash generation.
  class CanDefinition # :nodoc:
    include ActiveSupport::Inflector
    attr_reader :block
    
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

    # Accepts a hash of aliased actions and returns an array of actions which match.
    # This should be called before "matches?" and other checking methods since they
    # rely on the actions to be expanded.
    def expand_actions(aliased_actions)
      @expanded_actions = @actions.map do |action|
        aliased_actions[action] ? [action, *aliased_actions[action]] : action
      end.flatten
    end

    def matches?(action, subject)
      matches_action?(action) && matches_subject?(subject)
    end

    def can?(action, subject, extra_args)
      result = can_without_base_behavior?(action, subject, extra_args)
      @base_behavior ? result : !result
    end

    # Returns a hash of conditions. If the ":tableize => true" option is passed
    # it will pluralize the association conditions to match the table name.
    def conditions(options = {})
      if options[:tableize] && @conditions.kind_of?(Hash)
        @conditions.inject({}) do |tableized_conditions, (name, value)|
          name = tableize(name).to_sym if value.kind_of? Hash
          tableized_conditions[name] = value
          tableized_conditions
        end
      else
        @conditions
      end
    end

    def association_joins(conditions = @conditions)
      joins = []
      conditions.each do |name, value|
        if value.kind_of? Hash
          nested = association_joins(value)
          if nested
            joins << {name => nested}
          else
            joins << name
          end
        end
      end
      joins unless joins.empty?
    end

    private

    def matches_action?(action)
      @expanded_actions.include?(:manage) || @expanded_actions.include?(action)
    end

    def matches_subject?(subject)
      @subjects.include?(:all) || @subjects.include?(subject) || @subjects.any? { |sub| sub.kind_of?(Class) && subject.kind_of?(sub) }
    end

    def can_without_base_behavior?(action, subject, extra_args)
      if @block
        call_block(action, subject, extra_args)
      elsif @conditions && subject.class != Class
        matches_conditions? subject
      else
        true
      end
    end

    def matches_conditions?(subject, conditions = @conditions)
      conditions.all? do |name, value|
        attribute = subject.send(name)
        if value.kind_of?(Hash)
          if attribute.kind_of? Array
            attribute.any? { |element| matches_conditions? element, value }
          else
            matches_conditions? attribute, value
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
