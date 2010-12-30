module CanCan
  module Ability
    # could use alias_method_chain, but it's not worth adding activesupport as a gem dependency
    alias_method :query_without_mongoid_support, :query
    def query(action, subject)
      if defined?(::Mongoid) && subject <= CanCan::MongoidAdditions
        query_with_mongoid_support(action, subject)
      else
        query_without_mongoid_support(action, subject)
      end
    end

    def query_with_mongoid_support(action, subject)
      MongoidQuery.new(subject, relevant_rules_for_query(action, subject))
    end
  end

  class MongoidQuery
    def initialize(sanitizer, rules)
      @sanitizer = sanitizer
      @rules = rules
    end

    def conditions
      if @rules.size == 0
        false_query
      else
        @rules.first.instance_variable_get(:@conditions)
      end
    end

    def false_query
      # this query is sure to return no results
      {:_id => {'$exists' => false, '$type' => 7}}  # type 7 is an ObjectID (default for _id)
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



  module MongoidAdditions
    module ClassMethods
      # Returns a scope which fetches only the records that the passed ability
      # can perform a given action on. The action defaults to :read. This
      # is usually called from a controller and passed the +current_ability+.
      #
      #   @articles = Article.accessible_by(current_ability)
      #
      # Here only the articles which the user is able to read will be returned.
      # If the user does not have permission to read any articles then an empty
      # result is returned. Since this is a scope it can be combined with any
      # other scopes or pagination.
      #
      # An alternative action can optionally be passed as a second argument.
      #
      #   @articles = Article.accessible_by(current_ability, :update)
      #
      # Here only the articles which the user can update are returned. This
      # internally uses Ability#conditions method, see that for more information.
      def accessible_by(ability, action = :read)
        query = ability.query(action, self)
        where(query.conditions)
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end

# Info on monkeypatching Mongoid :
# http://log.mazniak.org/post/719062325/monkey-patching-activesupport-concern-and-you#footer
if defined?(::Mongoid)
  module Mongoid
    module Components
      old_block = @_included_block
      @_included_block = Proc.new do
        class_eval(&old_block) if old_block
        include CanCan::MongoidAdditions
      end
    end
  end
end
