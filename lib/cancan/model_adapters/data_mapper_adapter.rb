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

DataMapper::Model.class_eval do
  include CanCan::ModelAdditions::ClassMethods
end
