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
      @match_all = action.nil? && subject.nil?
      @base_behavior = base_behavior
      @actions = [action].flatten
      @subjects = [subject].flatten
      @conditions = conditions || {}
      @block = block
    end

    # Matches both the subject and action, not necessarily the conditions
    def relevant?(action, subject)
      subject = subject.values.first if subject.kind_of? Hash
      @match_all || (matches_action?(action) && matches_subject?(subject))
    end

    # Matches the block or conditions hash
    def matches_conditions?(action, subject, extra_args)
      if @match_all
        call_block_with_all(action, subject, extra_args)
      elsif @block && !subject_class?(subject)
        @block.call(subject, *extra_args)
      elsif @conditions.kind_of?(Hash) && subject.kind_of?(Hash)
        nested_subject_matches_conditions?(subject)
      elsif @conditions.kind_of?(Hash) && !subject_class?(subject)
        matches_conditions_hash?(subject)
      else
        # Don't stop at "cannot" definitions when there are conditions.
        @conditions.empty? ? true : @base_behavior
      end
    end

    def tableized_conditions(conditions = @conditions)
      return conditions unless conditions.kind_of? Hash
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

    def only_raw_sql?
      @block.nil? && !conditions_empty? && !@conditions.kind_of?(Hash)
    end

    def conditions_empty?
      @conditions == {} || @conditions.nil?
    end

    def associations_hash(conditions = @conditions)
      hash = {}
      conditions.map do |name, value|
        hash[name] = associations_hash(value) if value.kind_of? Hash
      end if conditions.kind_of? Hash
      hash
    end

    def attributes_from_conditions
      attributes = {}
      @conditions.each do |key, value|
        attributes[key] = value unless [Array, Range, Hash].include? value.class
      end if @conditions.kind_of? Hash
      attributes
    end

    private

    def subject_class?(subject)
      klass = (subject.kind_of?(Hash) ? subject.values.first : subject).class
      klass == Class || klass == Module
    end

    def matches_action?(action)
      @expanded_actions.include?(:manage) || @expanded_actions.include?(action)
    end

    def matches_subject?(subject)
      @subjects.include?(:all) || @subjects.include?(subject) || matches_subject_class?(subject)
    end

    def matches_subject_class?(subject)
      @subjects.any? { |sub| sub.kind_of?(Module) && (subject.kind_of?(sub) || subject.class.to_s == sub.to_s || subject.kind_of?(Module) && subject.ancestors.include?(sub)) }
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

    def nested_subject_matches_conditions?(subject_hash)
      parent, child = subject_hash.shift
      matches_conditions_hash?(parent, @conditions[parent.class.name.downcase.to_sym] || {})
    end

    def call_block_with_all(action, subject, extra_args)
      if subject.class == Class
        @block.call(action, subject, nil, *extra_args)
      else
        @block.call(action, subject.class, subject, *extra_args)
      end
    end
  end
end
