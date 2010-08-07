module CanCan

  # Generates the sql conditions and association joins for use in ActiveRecord queries.
  # Normally you will not use this class directly, but instead through ActiveRecordAdditions#accessible_by.
  class Query
    def initialize(sanitizer, can_definitions)
      @sanitizer = sanitizer
      @can_definitions = can_definitions
    end

    # Returns conditions intended to be used inside a database query. Normally you will not call this
    # method directly, but instead go through ActiveRecordAdditions#accessible_by.
    #
    # If there is only one "can" definition, a hash of conditions will be returned matching the one defined.
    #
    #   can :manage, User, :id => 1
    #   query(:manage, User).conditions # => { :id => 1 }
    #
    # If there are multiple "can" definitions, a SQL string will be returned to handle complex cases.
    #
    #   can :manage, User, :id => 1
    #   can :manage, User, :manager_id => 1
    #   cannot :manage, User, :self_managed => true
    #   query(:manage, User).conditions # => "not (self_managed = 't') AND ((manager_id = 1) OR (id = 1))"
    #
    def conditions
      if @can_definitions.size == 1 && @can_definitions.first.base_behavior
        # Return the conditions directly if there's just one definition
        @can_definitions.first.tableized_conditions
      else
        @can_definitions.reverse.inject(false_sql) do |sql, can_definition|
          merge_conditions(sql, can_definition.tableized_conditions, can_definition.base_behavior)
        end
      end
    end

    # Returns the associations used in conditions for the :joins option of a search.
    # See ActiveRecordAdditions#accessible_by for use in Active Record.
    def joins
      joins_hash = {}
      @can_definitions.each do |can_definition|
        merge_joins(joins_hash, can_definition.associations_hash)
      end
      clean_joins(joins_hash) unless joins_hash.empty?
    end

    private

    def merge_conditions(sql, conditions_hash, behavior)
      if conditions_hash.blank?
        behavior ? true_sql : false_sql
      else
        conditions = sanitize_sql(conditions_hash)
        case sql
        when true_sql
          behavior ? true_sql : "not (#{conditions})"
        when false_sql
          behavior ? conditions : false_sql
        else
          behavior ? "(#{conditions}) OR (#{sql})" : "not (#{conditions}) AND (#{sql})"
        end
      end
    end

    def false_sql
      sanitize_sql(['?=?', true, false])
    end

    def true_sql
      sanitize_sql(['?=?', true, true])
    end

    def sanitize_sql(conditions)
      @sanitizer.send(:sanitize_sql, conditions)
    end

    # Takes two hashes and does a deep merge.
    def merge_joins(base, add)
      add.each do |name, nested|
        if base[name].is_a?(Hash) && !nested.empty?
          merge_joins(base[name], nested)
        else
          base[name] = nested
        end
      end
    end

    # Removes empty hashes and moves everything into arrays.
    def clean_joins(joins_hash)
      joins = []
      joins_hash.each do |name, nested|
        joins << (nested.empty? ? name : {name => clean_joins(nested)})
      end
      joins
    end
  end
end
