module CanCan
  module ModelAdapters
    class AbstractAdapter
      def initialize(model_class, rules)
        @model_class = model_class
        @rules = rules
      end
    end
  end
end
