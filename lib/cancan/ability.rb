module CanCan
  module Ability
    def self.included(base)
      base.extend ClassMethods
    end
    
    def can?(action, target)
      self.class.can_history.reverse.each do |can_action, can_target, can_block|
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
      false
    end
    
    module ClassMethods
      attr_reader :can_history
      
      def can(action, target, &block)
        @can_history ||= []
        @can_history << [action, target, block]
      end
    end
  end
end
