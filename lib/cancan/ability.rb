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
    # Use to check the user's permission for a given action and object.
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
    def can?(action, subject, *extra_args)
      matching_can_definition(action, subject) do |base_behavior, defined_actions, defined_subjects, defined_conditions, defined_block|
        result = can_perform_action?(action, subject, defined_actions, defined_subjects, defined_conditions, defined_block, extra_args)
        return base_behavior ? result : !result
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
    # Here the user can only see active projects which he owns. See ControllerAdditions#conditions for a way to
    # use this in database queries.
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
      @can_definitions ||= []
      @can_definitions << [true, action, subject, conditions, block]
    end
    
    # Define an ability which cannot be done. Accepts the same arguments as "can".
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
      @can_definitions ||= []
      @can_definitions << [false, action, subject, conditions, block]
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
    
    # Returns a hash of conditions which match the given ability. This is useful if you need to generate a database
    # query based on the current ability.
    # 
    #   can :read, Article, :visible => true
    #   conditions :read, Article # returns { :visible => true }
    # 
    # Normally you will not call this method directly, but instead go through ActiveRecordAdditions#accessible_by method.
    # 
    # If the ability is not defined then false is returned so be sure to take that into consideration.
    # If the ability is defined using a block then this will raise an exception since a hash of conditions cannot be
    # determined from that.
    def conditions(action, subject)
      matching_can_definition(action, subject) do |base_behavior, defined_actions, defined_subjects, defined_conditions, defined_block|
        raise Error, "Cannot determine ability conditions from block for #{action.inspect} #{subject.inspect}" if defined_block
        return defined_conditions || {}
      end
      false
    end
    
    private
    
    def matching_can_definition(action, subject, &block)
      (@can_definitions || []).reverse.each do |base_behavior, defined_action, defined_subject, defined_conditions, defined_block|
        defined_actions = expand_actions(defined_action)
        defined_subjects = [defined_subject].flatten
        if includes_action?(defined_actions, action) && includes_subject?(defined_subjects, subject)
          return block.call(base_behavior, defined_actions, defined_subjects, defined_conditions, defined_block)
        end
      end
    end
    
    def default_alias_actions
      {
        :read => [:index, :show],
        :create => [:new],
        :update => [:edit],
      }
    end
    
    def expand_actions(actions)
      [actions].flatten.map do |action|
        if aliased_actions[action]
          [action, *aliased_actions[action]]
        else
          action
        end
      end.flatten
    end
    
    def can_perform_action?(action, subject, defined_actions, defined_subjects, defined_conditions, defined_block, extra_args)
      if defined_block
        block_args = []
        block_args << action if defined_actions.include?(:manage)
        block_args << (subject.class == Class ? subject : subject.class) if defined_subjects.include?(:all)
        block_args << (subject.class == Class ? nil : subject)
        block_args += extra_args
        defined_block.call(*block_args)
      elsif defined_conditions
        if subject.class == Class
          true
        else
          matches_conditions? subject, defined_conditions
        end
      else
        true
      end
    end
    
    def matches_conditions?(subject, defined_conditions)
      defined_conditions.all? do |name, value|
        attribute = subject.send(name)
        if value.kind_of?(Hash)
          matches_conditions? attribute, value
        elsif value.kind_of?(Array) || value.kind_of?(Range)
          value.include? attribute
        else
          attribute == value
        end
      end
    end
    
    def includes_action?(actions, action)
      actions.include?(:manage) || actions.include?(action)
    end
    
    def includes_subject?(subjects, subject)
      subjects.include?(:all) || subjects.include?(subject) || subjects.any? { |c| c.kind_of?(Class) && subject.kind_of?(c) }
    end
  end
end
