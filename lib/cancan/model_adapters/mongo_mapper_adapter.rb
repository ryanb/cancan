module CanCan
  module ModelAdapters
    class MongoMapperAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= MongoMapper::Document
      end

      def self.override_conditions_hash_matching?(subject, conditions)
        conditions.any? do |k,v|
          key_is_not_symbol = lambda { !k.kind_of?(Symbol) }
          subject_value_is_array = lambda do
            subject.respond_to?(k) && subject.send(k).is_a?(Array)
          end

          key_is_not_symbol.call || subject_value_is_array.call
        end
      end

      def self.matches_conditions_hash?(subject, conditions)
        subject.class.where(conditions).include? subject
      end

      def database_records
        if @rules.size == 0
          @model_class.where(:_id => {:$exists => false, :$type => 7}) # return no records
        elsif @rules.size == 1
          @model_class.where(@rules[0].conditions)
        else
          # we only need to process can rules if
          # there are no rules with empty conditions
          rules = @rules.reject { |rule| rule.conditions.empty? }
          process_can_rules = @rules.count == rules.count
          rules.inject(@model_class.where) do |records, rule|
            if process_can_rules && rule.base_behavior
              records.where rule.conditions
            elsif !rule.base_behavior
              records.remove rule.conditions
              records
            else
              records
            end
          end
        end
      end
    end
  end
end

module MongoMapper::Document::ClassMethods
  include CanCan::ModelAdditions::ClassMethods
end
