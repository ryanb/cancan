module CanCan
  # This module is automatically included into all Active Record.
  module ActiveRecordAdditions
    module ClassMethods
      def can(ability, action)
        where(ability.conditions(action, self) || {:id => nil})
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
    end
  end
end

if defined? ActiveRecord
  ActiveRecord::Base.class_eval do
    include CanCan::ActiveRecordAdditions
  end
end
