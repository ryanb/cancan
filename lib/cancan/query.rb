module CanCan

  # Generates the sql conditions and association joins for use in ActiveRecord queries.
  # Normally you will not use this class directly, but instead through ActiveRecordAdditions#accessible_by.
  class Query
    def initialize(sanitizer, can_definitions)
      @sanitizer = sanitizer
      @can_definitions = can_definitions
    end

    # Returns an array of arrays composing from desired action and hash of conditions which match the given ability.
    # This is useful if you need to generate a database query based on the current ability.
    # 
    #   can :read, Article, :visible => true
    #   conditions :read, Article # returns [ [ true, { :visible => true } ] ]
    #
    #   can :read, Article, :visible => true
    #   cannot :read, Article, :blocked => true
    #   conditions :read, Article # returns [ [ false, { :blocked => true } ], [ true, { :visible => true } ] ]
    # 
    # Normally you will not call this method directly, but instead go through ActiveRecordAdditions#accessible_by method.
    #
    # If the ability is not defined then false is returned so be sure to take that into consideration.
    # If the ability is defined using a block then this will raise an exception since a hash of conditions cannot be
    # determined from that.
    def conditions
      unless @can_definitions.empty?
        @can_definitions.map do |can_definition|
          [can_definition.base_behavior, can_definition.tableized_conditions]
        end
      else
        false
      end
    end
    
    # Returns sql conditions for object, which responds to :sanitize_sql .
    # This is useful if you need to generate a database query based on the current ability.
    # 
    #   can :manage, User, :id => 1
    #   can :manage, User, :manager_id => 1
    #   cannot :manage, User, :self_managed => true
    #   sql_conditions :manage, User # returns not (self_managed = 't') AND ((manager_id = 1) OR (id = 1))
    #
    # Normally you will not call this method directly, but instead go through ActiveRecordAdditions#accessible_by method.
    # 
    # If the ability is not defined then false is returned so be sure to take that into consideration.
    # If there is just one :can ability, it conditions returned untouched.
    # If the ability is defined using a block then this will raise an exception since a hash of conditions cannot be
    # determined from that.
    def sql_conditions
      conds = conditions
      return false if conds == false
      return (conds[0][1] || {}) if conds.size==1 && conds[0][0] == true # to match previous spec
      
      true_cond = sanitize_sql(['?=?', true, true])
      false_cond = sanitize_sql(['?=?', true, false])
      conds.reverse.inject(false_cond) do |sql, action|
        behavior, condition = action
        if condition && condition != {}
          condition = sanitize_sql(condition)
          case sql
            when true_cond
              behavior ? true_cond : "not (#{condition})"
            when false_cond
              behavior ? condition : false_cond
            else
              behavior ? "(#{condition}) OR (#{sql})" : "not (#{condition}) AND (#{sql})"
          end
        else
          behavior ? true_cond : false_cond
        end
      end
    end
    
    # Returns the associations used in conditions. This is usually used in the :joins option for a search.
    # See ActiveRecordAdditions#accessible_by for use in Active Record.
    def association_joins
      unless @can_definitions.empty?
        collect_association_joins(@can_definitions)
      else
        nil
      end
    end
    
    private

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
