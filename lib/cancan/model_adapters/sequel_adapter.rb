module CanCan
  module ModelAdapters
    class SequelAdapter < AbstractAdapter
      def self.for_class?(model_class)
        model_class <= Sequel::Model
      end

      def self.find(model_class, id)
        model_class[id]
      end

      def self.override_condition_matching?(subject, name, value)
        value.kind_of?(Hash)
      end

      def self.matches_condition?(subject, name, value)
        obj = subject.send(name)
        if obj.nil?
          false
        else
          value.each do |k, v|
            if v.kind_of?(Hash)
              return false unless self.matches_condition?(obj, k, v)
            elsif obj.send(k) != v
              return false
            end
          end
        end
      end

      def database_records
        if @rules.size == 0
          @model_class.where('1=0')
        else
          # only need to process can rules if there are no can rule with empty conditions
          rules = @rules.reject { |rule| rule.base_behavior && rule.conditions.empty? }
          rules.reject! { |rule| rule.base_behavior } if rules.count < @rules.count

          can_condition_added = false
          rules.reverse.inject(@model_class.dataset) do |records, rule|
            normalized_conditions = normalize_conditions(rule.conditions)
            if rule.base_behavior
              if can_condition_added
                records.or normalized_conditions
              else
                can_condition_added = true
                records.where normalized_conditions
              end
            else
              records.exclude normalized_conditions
            end
          end
        end
      end

      private

      def normalize_conditions(conditions, model_class = @model_class)
        return conditions unless conditions.kind_of? Hash
        conditions.inject({}) do |result_hash, (name, value)|
          if value.kind_of? Hash
            value = value.dup
            association_class = model_class.association_reflection(name).associated_class
            nested = value.inject({}) do |nested, (k, v)|
              if v.kind_of?(Hash)
                value.delete(k)
                nested_class = association_class.association_reflection(k).associated_class
                nested[k] = nested_class.where(normalize_conditions(v, association_class))
              else
                nested[k] = v
              end
              nested
            end
            result_hash[name] = association_class.where(nested)
          else
            result_hash[name] = value
          end
          result_hash
        end
      end
    end
  end
end

Sequel::Model.class_eval do
  include CanCan::ModelAdditions
end
