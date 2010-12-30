module CanCan
  module ModelAdapters
    class DataMapperAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= DataMapper::Resource
      end

      def database_records
        scope = @model_class.all(:conditions => ['true=false'])
        conditions.each do |condition|
          scope += @model_class.all(:conditions => condition)
        end
        scope
      end

      def conditions
        @rules.map(&:conditions)
      end
    end
  end
end

module CanCan
  module DataMapperAdditions
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
        ability.model_adapter(self, action).database_records
      end
    end
  end
end

if Object.const_defined?('DataMapper')
  DataMapper::Model.class_eval do
    include CanCan::DataMapperAdditions::ClassMethods
  end
end
