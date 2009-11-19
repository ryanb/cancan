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
    attr_accessor :user

    # Use to check the user's permission for a given action and object.
    # 
    #   can? :destroy, @project
    # 
    # You can also pass the class instead of an instance (if you don't have one handy).
    # 
    #   can? :create, Project
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
    def can?(original_action, target) # TODO this could use some refactoring
      (@can_history || []).reverse.each do |can_action, can_target, can_block|
        can_actions = [can_action].flatten
        can_targets = [can_target].flatten
        possible_actions_for(original_action).each do |action|
          if (can_actions.include?(:manage) || can_actions.include?(action)) && (can_targets.include?(:all) || can_targets.include?(target) || can_targets.any? { |c| target.kind_of?(c) })
            if can_block.nil?
              return true
            else
              block_args = []
              block_args << action if can_actions.include?(:manage)
              block_args << (target.class == Class ? target : target.class) if can_targets.include?(:all)
              block_args << (target.class == Class ? nil : target)
              return can_block.call(*block_args)
            end
          end
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
    # You can pass a block to provide logic based on the article's attributes.
    #
    #   can :update, Article do |article|
    #     article && article.user == user
    #   end
    # 
    # If the block returns true then the user has that :update ability for that article, otherwise he
    # will be denied access. It's possible for the passed in model to be nil if one isn't specified,
    # so be sure to take that into consideration.
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
    def can(action, target, &block)
      @can_history ||= []
      @can_history << [action, target, block]
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
      @aliased_actions ||= default_alias_actions
      target = args.pop[:to]
      @aliased_actions[target] = args
    end
    
    private
    
    def default_alias_actions
      {
        :read => [:index, :show],
        :create => [:new],
        :update => [:edit],
      }
    end
    
    def possible_actions_for(initial_action)
      actions = [initial_action]
      (@aliased_actions || default_alias_actions).each do |target, aliases|
        actions += possible_actions_for(target) if aliases.include? initial_action
      end
      actions
    end
  end
end
