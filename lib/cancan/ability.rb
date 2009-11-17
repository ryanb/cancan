module CanCan
  module Ability
    attr_accessor :user
    
    def can?(original_action, target) # TODO this could use some refactoring
      (@can_history || []).reverse.each do |can_action, can_target, can_block|
        possible_actions_for(original_action).each do |action|
          if (can_action == :manage || can_action == action) && (can_target == :all || can_target == target || target.kind_of?(can_target))
            if can_block.nil?
              return true
            else
              block_args = []
              block_args << action if can_action == :manage
              block_args << (target.class == Class ? target : target.class) if can_target == :all
              block_args << (target.class == Class ? nil : target)
              return can_block.call(*block_args)
            end
          end
        end
      end
      false
    end
    
    def possible_actions_for(initial_action)
      actions = [initial_action]
      (@aliased_actions || default_alias_actions).each do |target, aliases|
        actions += possible_actions_for(target) if aliases.include? initial_action
      end
      actions
    end
      
    def can(action, target, &block)
      @can_history ||= []
      @can_history << [action, target, block]
    end
    
    def alias_action(*args)
      @aliased_actions ||= default_alias_actions
      target = args.pop[:to]
      @aliased_actions[target] = args
    end
    
    def default_alias_actions
      {
        :read => [:index, :show],
        :create => [:new],
        :update => [:edit],
      }
    end
    
    def prepare(user)
      # to be overriden by included class
    end
  end
end
