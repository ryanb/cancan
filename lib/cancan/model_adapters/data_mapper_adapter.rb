module CanCan
  module Ability
    # could use alias_method_chain, but it's not worth adding activesupport as a gem dependency
    alias_method :query_without_data_mapper_support, :query
    def query(action, subject)
      if Object.const_defined?('DataMapper') && subject <= DataMapper::Resource
        query_with_data_mapper_support(action, subject)
      else
        query_without_data_mapper_support(action, subject)
      end
    end

    def query_with_data_mapper_support(action, subject)
      DataMapperQuery.new(subject, relevant_rules_for_query(action, subject))
    end
  end

  class DataMapperQuery
    def initialize(sanitizer, rules)
      @sanitizer = sanitizer
      @rules = rules
    end

    def conditions
      @rules.map {|r| r.instance_variable_get(:@conditions) }
    end
  end

  # This module is automatically included into all Active Record models.
  module DataMapperAdditions
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

        scope = all(:conditions => ['true=false'])
        query.conditions.each do |condition|
          scope += all(:conditions => condition)
        end

        return scope
      end
    end
  end
end

if Object.const_defined?('DataMapper')
  DataMapper::Model.class_eval do
    include CanCan::DataMapperAdditions::ClassMethods
  end
end
