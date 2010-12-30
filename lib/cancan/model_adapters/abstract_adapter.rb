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
    end
  end
end
