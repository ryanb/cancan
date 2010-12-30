module CanCan
  module ModelAdapters
    class MongoidAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= Mongoid::Document
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

  # customize to handle Mongoid queries in ability definitions conditions
  # Mongoid Criteria are simpler to check than normal conditions hashes
  # When no conditions are given, true should be returned.
  # The default CanCan behavior relies on the fact that conditions.all? will return true when conditions is empty
  # The way ruby handles all? for empty hashes can be unexpected:
  #   {}.all?{|a| a == 5}
  #   => true
  #   {}.all?{|a| a != 5}
  #   => true
  class Rule
    def matches_conditions_hash_with_mongoid_subject?(subject, conditions = @conditions)
      if defined?(::Mongoid) && subject.class.include?(::Mongoid::Document) && conditions.any?{|k,v| !k.kind_of?(Symbol)}
        if conditions.empty?
          true
        else
          subject.class.where(conditions).include?(subject)  # just use Mongoid's where function
        end
      else
        matches_conditions_hash_without_mongoid_subject? subject, conditions
      end
    end

    # could use alias_method_chain, but it's not worth adding activesupport as a gem dependency
    alias_method :matches_conditions_hash_without_mongoid_subject?, :matches_conditions_hash?
    alias_method :matches_conditions_hash?, :matches_conditions_hash_with_mongoid_subject?
  end
end
