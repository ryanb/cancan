module CanCan
  # This module is automatically included into all Active Record models.
  module ActiveRecordAdditions
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
        conditions = ability.conditions(action, self, :tableize => true) || {:id => nil}
        joins = ability.association_joins(action, self)
        if respond_to? :where
          where(conditions).joins(joins)
        else
          scoped(:conditions => conditions, :joins => joins)
        end
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
