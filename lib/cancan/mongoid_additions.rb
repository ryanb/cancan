module CanCan

  module Ability
    alias_method :query_without_mongoid_support, :query
    def query(action, subject)
      if Object.const_defined?(:Mongoid) && subject <= CanCan::MongoidAdditions
        query_with_mongoid_support(action, subject)
      else
        query_without_mongoid_support(action, subject)
      end
    end
    
    def query_with_mongoid_support(action, subject)
      MongoidQuery.new(subject, relevant_can_definitions_for_query(action, subject))
    end
  end
  
  class MongoidQuery
    def initialize(sanitizer, can_definitions)
      @sanitizer = sanitizer
      @can_definitions = can_definitions
    end    
    
    def conditions
      @can_definitions.first.try(:tableized_conditions)
    end
  end

  module MongoidAdditions
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
        query = ability.query(action, self)        
        if query.conditions.blank?
          # this query is sure to return no results
          # we need this so there is a Mongoid::Criteria object to return, since an empty array would cause problems
          where({:_id => {'$exists' => true, '$type' => 2}})  
        else   
          where(query.conditions)
        end
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
    end
  end
end

# Info on monkeypatching Mongoid : 
# http://log.mazniak.org/post/719062325/monkey-patching-activesupport-concern-and-you#footer
if defined? Mongoid
  module Mongoid
    module Components
      old_block = @_included_block
      @_included_block = Proc.new do 
        class_eval(&old_block) if old_block
        include CanCan::MongoidAdditions
      end
    end
  end  
end