module CanCan
  module ModelAdapters
    class ActiveHashAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= ActiveHash::Base
      end

      def database_records
        records = []
        return records if @rules.size.zero?

        all = @model_class.all
        cans, cannots = @rules.partition { |r| r.base_behavior }
        return all if cans.empty?

        cans.each do |rule|
          records |= @model_class.where(rule.conditions)
        end

        cannots.each do |rule|
          records -= @model_class.where(rule.conditions)
        end

        records
      end
    end
  end
end

ActiveHash::Base.class_eval do
  include CanCan::ModelAdditions
end
