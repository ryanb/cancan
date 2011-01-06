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
        @model_class.where(conditions)
      end

      def conditions
        if @rules.size == 0
          false_query
        else
          @rules.first.conditions
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