module CanCan
  module ModelAdapters
    class DataMapperAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= DataMapper::Resource
      end

      def self.override_conditions_hash_matching?(subject, conditions)
        conditions.any? { |k,v| !k.kind_of?(Symbol) }
      end

      def self.matches_conditions_hash?(subject, conditions)
        subject.class.all(:conditions => conditions).include?(subject) # TODO don't use a database query here for performance and other instances
      end

      def database_records
        scope = @model_class.all(:conditions => ["0=1"])
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

DataMapper::Model.class_eval do
  include CanCan::ModelAdditions::ClassMethods
end
