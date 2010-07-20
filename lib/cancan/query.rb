module CanCan

  # Generates the sql conditions and association joins for use in ActiveRecord queries.
  # Normally you will not use this class directly, but instead through ActiveRecordAdditions#accessible_by.
  class Query
    def initialize(sanitizer, can_definitions)
      @sanitizer = sanitizer
      @can_definitions = can_definitions
    end
    
    # Returns a string of SQL conditions which match the ability query.
    # 
    #   can :manage, User, :id => 1
    #   can :manage, User, :manager_id => 1
    #   cannot :manage, User, :self_managed => true
    #   query(:manage, User).conditions # => "not (self_managed = 't') AND ((manager_id = 1) OR (id = 1))"
    #
    # Normally you will not call this method directly, but instead go through ActiveRecordAdditions#accessible_by.
    # 
    # If there is just one :can ability, it conditions returned untouched.
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
    
    # Returns the associations used in conditions for the :joins option of a search
    # See ActiveRecordAdditions#accessible_by for use in Active Record.
    def joins
      unless @can_definitions.empty?
        collect_association_joins(@can_definitions)
      end
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
      @sanitizer.sanitize_sql(conditions)
    end
    
    def collect_association_joins(can_definitions)
      joins = []
      @can_definitions.each do |can_definition|
        merge_association_joins(joins, can_definition.association_joins || [])
      end
      joins = clear_association_joins(joins)
      joins unless joins.empty?
    end
    
    def merge_association_joins(what, with)
      with.each do |join|
        name, nested = join.each_pair.first
        if at = what.detect{|h| h.has_key?(name) }
          at[name] = merge_association_joins(at[name], nested)
        else
          what << join
        end
      end
    end
    
    def clear_association_joins(joins)
      joins.map do |join| 
        name, nested = join.each_pair.first
        nested.empty? ? name : {name => clear_association_joins(nested)}
      end
    end
  end
end
