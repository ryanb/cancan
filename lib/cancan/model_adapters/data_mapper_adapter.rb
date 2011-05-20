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
        collection = DataMapper::Collection.new(subject.query, [ subject ])
        !!collection.first(conditions)
      end

      def database_records
        scope = @model_class.all(:conditions => ["0 = 1"])
        cans, cannots = @rules.partition { |r| r.base_behavior }
        return scope if cans.empty?
        # apply unions first, then differences. this mean cannot overrides can
        cans.each    { |r| scope += @model_class.all(:conditions => r.conditions) }
        cannots.each { |r| scope -= @model_class.all(:conditions => r.conditions) }
        scope
      end

      def finder
        'get'
      end
    end # class DataMapper
  end # module ModelAdapters
end # module CanCan

DataMapper::Model.class_eval do
  include CanCan::ModelAdditions::ClassMethods
end
