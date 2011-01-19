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
          @model_class.where(false_query)
        else
          criteria = @model_class.all
          @rules.each do |rule|
            criteria = chain_criteria(rule, criteria)
          end
          criteria
        end
      end
      
      def chain_criteria rule, criteria
        if rule.base_behavior
          criteria.or(rule.conditions)
        else
          criteria.excludes(rule.conditions)
        end
      end

      def false_query
        # this query is sure to return no results
        {:_id => {'$exists' => false, '$type' => 7}}  # type 7 is an ObjectID (default for _id)
      end
    end
  end
end

# simplest way to add `accessible_by` to all Mongoid Documents
module Mongoid::Document::ClassMethods
  include CanCan::ModelAdditions::ClassMethods
end