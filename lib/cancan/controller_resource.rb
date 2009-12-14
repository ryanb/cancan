module CanCan
  class ControllerResource # :nodoc:
    def initialize(controller, name, parent = nil, options = {})
      @controller = controller
      @name = name
      @parent = parent
      @options = options
    end
    
    def model_class
      @options[:class] || @name.to_s.camelize.constantize
    end
    
    def find(id)
      self.model_instance ||= base.find(id)
    end
    
    def build(attributes)
      if base.kind_of? Class
        self.model_instance ||= base.new(attributes)
      else
        self.model_instance ||= base.build(attributes)
      end
    end
    
    def model_instance
      @controller.instance_variable_get("@#{@name}")
    end
    
    def model_instance=(instance)
      @controller.instance_variable_set("@#{@name}", instance)
    end
    
    private
    
    def base
      @parent ? @parent.model_instance.send(@name.to_s.pluralize) : model_class
    end
  end
end
