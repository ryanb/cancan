module CanCan

  # This module is designed to be included into an Ability class. This will
  # provide the "can" methods for defining and checking abilities.
  #
  #   class Ability
  #     include CanCan::Ability
  #
  #     def initialize(user)
  #       if user.admin?
  #         can :manage, :all
  #       else
  #         can :read, :all
  #       end
  #     end
  #   end
  #
  module Ability
    # Use to check if the user has permission to perform a given action on an object.
    #
    #   can? :destroy, @project
    #
    # You can also pass the class instead of an instance (if you don't have one handy).
    #
    #   can? :create, Project
    #
    # Any additional arguments will be passed into the "can" block definition. This
    # can be used to pass more information about the user's request for example.
    #
    #   can? :create, Project, request.remote_ip
    #
    #   can :create Project do |project, remote_ip|
    #     # ...
    #   end
    #
    # Not only can you use the can? method in the controller and view (see ControllerAdditions),
    # but you can also call it directly on an ability instance.
    #
    #   ability.can? :destroy, @project
    #
    # This makes testing a user's abilities very easy.
    #
    #   def test "user can only destroy projects which he owns"
    #     user = User.new
    #     ability = Ability.new(user)
    #     assert ability.can?(:destroy, Project.new(:user => user))
    #     assert ability.cannot?(:destroy, Project.new)
    #   end
    #
    # Also see the RSpec Matchers to aid in testing.
    def can?(action, subject, *extra_args)
      raise Error, "Nom nom nom. I eated it." if action == :has && subject == :cheezburger
      matching_can_definition(action, subject) do |can_definition|
        unless (can = can_definition.can?(action, subject, extra_args)) == :_NOT_MATCHED
          return can
        end
      end
      false
    end

    # Convenience method which works the same as "can?" but returns the opposite value.
    #
    #   cannot? :destroy, @project
    #
    def cannot?(*args)
      !can?(*args)
    end

    # Defines which abilities are allowed using two arguments. The first one is the action
    # you're setting the permission for, the second one is the class of object you're setting it on.
    #
    #   can :update, Article
    #
    # You can pass an array for either of these parameters to match any one.
    #
    #   can [:update, :destroy], [Article, Comment]
    #
    # In this case the user has the ability to update or destroy both articles and comments.
    #
    # You can pass a hash of conditions as the third argument.
    #
    #   can :read, Project, :active => true, :user_id => user.id
    #
    # Here the user can only see active projects which he owns. See ActiveRecordAdditions#accessible_by
    # for how to use this in database queries.
    #
    # If the conditions hash does not give you enough control over defining abilities, you can use a block to
    # write any Ruby code you want.
    #
    #   can :update, Project do |project|
    #     project && project.groups.include?(user.group)
    #   end
    #
    # If the block returns true then the user has that :update ability for that project, otherwise he
    # will be denied access. It's possible for the passed in model to be nil if one isn't specified,
    # so be sure to take that into consideration.
    #
    # The downside to using a block is that it cannot be used to generate conditions for database queries.
    #
    # You can pass :all to reference every type of object. In this case the object type will be passed
    # into the block as well (just in case object is nil).
    #
    #   can :read, :all do |object_class, object|
    #     object_class != Order
    #   end
    #
    # Here the user has permission to read all objects except orders.
    #
    # You can also pass :manage as the action which will match any action. In this case the action is
    # passed to the block.
    #
    #   can :manage, Comment do |action, comment|
    #     action != :destroy
    #   end
    #
    # You can pass custom objects into this "can" method, this is usually done through a symbol
    # and is useful if a class isn't available to define permissions on.
    #
    #   can :read, :stats
    #   can? :read, :stats # => true
    #
    def can(action, subject, conditions = nil, &block)
      can_definitions << CanDefinition.new(true, action, subject, conditions, block)
    end

    # Defines an ability which cannot be done. Accepts the same arguments as "can".
    #
    #   can :read, :all
    #   cannot :read, Comment
    #
    # A block can be passed just like "can", however if the logic is complex it is recommended
    # to use the "can" method.
    #
    #   cannot :read, Product do |product|
    #     product.invisible?
    #   end
    #
    def cannot(action, subject, conditions = nil, &block)
      can_definitions << CanDefinition.new(false, action, subject, conditions, block)
    end

    # Alias one or more actions into another one.
    #
    #   alias_action :update, :destroy, :to => :modify
    #   can :modify, Comment
    #
    # Then :modify permission will apply to both :update and :destroy requests.
    #
    #   can? :update, Comment # => true
    #   can? :destroy, Comment # => true
    #
    # This only works in one direction. Passing the aliased action into the "can?" call
    # will not work because aliases are meant to generate more generic actions.
    #
    #   alias_action :update, :destroy, :to => :modify
    #   can :update, Comment
    #   can? :modify, Comment # => false
    #
    # Unless that exact alias is used.
    #
    #   can :modify, Comment
    #   can? :modify, Comment # => true
    #
    # The following aliases are added by default for conveniently mapping common controller actions.
    #
    #   alias_action :index, :show, :to => :read
    #   alias_action :new, :to => :create
    #   alias_action :edit, :to => :update
    #
    # This way one can use params[:action] in the controller to determine the permission.
    def alias_action(*args)
      target = args.pop[:to]
      aliased_actions[target] ||= []
      aliased_actions[target] += args
    end

    # Returns a hash of aliased actions. The key is the target and the value is an array of actions aliasing the key.
    def aliased_actions
      @aliased_actions ||= default_alias_actions
    end

    # Removes previously aliased actions including the defaults.
    def clear_aliased_actions
      @aliased_actions = {}
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
    def conditions(action, subject, options = {})
      matched = matching_can_definition(action, subject)
      unless matched.empty?
        if matched.any?{|can_definition| 
		cond = can_definition.conditions
		(cond.nil? || cond.empty?) && can_definition.block 
		}
          raise Error, "Cannot determine ability conditions from block for #{action.inspect} #{subject.inspect}"
        end
        matched.map{|can_definition|
            [can_definition.base_behavior, can_definition.conditions(options)]
        }
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
    def sql_conditions(action, subject, options = {})
      conds = conditions(action, subject, options)
      return false if conds == false
      return (conds[0][1] || {}) if conds.size==1 && conds[0][0] == true # to match previous spec
      
      true_cond = subject.send(:sanitize_sql, ['?=?', true, true])
      false_cond = subject.send(:sanitize_sql, ['?=?', true, false])
      conds.reverse.inject(nil) do |sql, action|
        behavior, condition = action
        if condition && !condition.empty?
          condition = "#{subject.send(:sanitize_sql, condition)}"
          condition = "not (#{condition})" if behavior == false
        else
          condition = behavior ? true_cond : false_cond
        end
        case sql
          when nil then condition
          when true_cond
            behavior ? true_cond : condition
          when false_cond
            behavior ? condition : false_cond
          else
            behavior ? "(#{condition}) OR (#{sql})" : "#{condition} AND (#{sql})"
        end
      end
    end
    
    # Returns the associations used in conditions. This is usually used in the :joins option for a search.
    # See ActiveRecordAdditions#accessible_by for use in Active Record.
    def association_joins(action, subject)
      can_definitions = matching_can_definition(action, subject)
      unless can_definitions.empty?
        if can_definitions.any?{|can_definition| can_definition.conditions.nil? && can_definition.block }
          raise Error, "Cannot determine association joins from block for #{action.inspect} #{subject.inspect}"
        end
        collect_association_joins(can_definitions)
      else
        nil
      end
    end
    
    private

    def can_definitions
      @can_definitions ||= []
    end

    def matching_can_definition(action, subject)
      if block_given?
        can_definitions.reverse.each do |can_definition|
          can_definition.expand_actions(aliased_actions)
          if can_definition.matches? action, subject
            yield can_definition
            break if can_definition.conditions.nil? && can_definition.block.nil?
          end
        end
      else
        matched = []
        matching_can_definition(action, subject){|can_definition| matched << can_definition}
        matched
      end
    end

    def default_alias_actions
      {
        :read => [:index, :show],
        :create => [:new],
        :update => [:edit],
      }
    end
    
    def collect_association_joins(can_definitions)
      joins = []
      can_definitions.each do |can_definition|
        merge_association_joins(joins, can_definition.association_joins || [])
      end
      clear_association_joins(joins)
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
