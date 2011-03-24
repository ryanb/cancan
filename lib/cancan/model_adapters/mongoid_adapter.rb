module CanCan
  module ModelAdapters
    class MongoidAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= Mongoid::Document
      end

      def self.override_conditions_hash_matching?(subject, conditions)
        conditions.any? { |k,v| !k.kind_of?(Symbol) }
      end

      def self.matches_conditions_hash?(subject, conditions)
        # To avoid hitting the db, retrieve the raw Mongo selector from
        # the Mongoid Criteria and use Mongoid::Matchers#matches?
        subject.matches?( subject.class.where(conditions).selector )
      end

      def database_records
        if @rules.size == 0  
          @model_class.where(:_id => {'$exists' => false, '$type' => 7}) # return no records in Mongoid
        else
          @rules.inject(@model_class.all) do |records, rule|
            if rule.conditions.empty?
              records
            elsif rule.base_behavior
              records.or(rule.conditions)
            else
              records.excludes(rule.conditions)
            end
          end
        end
      end
    end
  end
end

# simplest way to add `accessible_by` to all Mongoid Documents
module Mongoid::Document::ClassMethods
  include CanCan::ModelAdditions::ClassMethods
end