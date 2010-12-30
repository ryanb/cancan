module CanCan
  module ModelAdapters
    class AbstractAdapter
      def self.inherited(subclass)
        @subclasses ||= []
        @subclasses << subclass
      end

      def self.adapter_class(model_class)
        @subclasses.detect { |subclass| subclass.for_class?(model_class) } || DefaultAdapter
      end

      # Used to determine if the given adapter should be used for the passed in class.
      def self.for_class?(member_class)
        false # override in subclass
      end

      def initialize(model_class, rules)
        @model_class = model_class
        @rules = rules
      end

      def database_records
        # This should be overridden in a subclass to return records which match @rules
        raise NotImplemented, "This model adapter does not support fetching records from the database."
      end
    end
  end
end
