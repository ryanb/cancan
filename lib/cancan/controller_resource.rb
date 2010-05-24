module CanCan
  # Used internally to load and authorize a given controller resource.
  # This manages finding or building an instance of the resource. If a
  # parent is given it will go through the association.
  class ControllerResource # :nodoc:
    def initialize(controller, name, parent = nil, options = {})
      raise ImplementationRemoved, "The :class option has been renamed to :resource for specifying the class in CanCan." if options.has_key? :class
      @controller = controller
      @name = name
      @parent = parent
      @options = options
    end
    
    # Returns the class used for this resource. This can be overriden by the :resource option.
    # Sometimes one will use a symbol as the resource if a class does not exist for it. In that
    # case "find" and "build" should not be called on it.
    def model_class
      resource_class = @options[:resource]
      if resource_class.nil?
        @name.to_s.camelize.constantize
      elsif resource_class.kind_of? String
        resource_class.constantize
      else
        resource_class # could be a symbol
      end
    end
    
    def find(id)
      self.model_instance ||= base.find(id)
    end
    
    # Build a new instance of this resource. If it is a class we just call "new" otherwise
    # it's an associaiton and "build" is used.
    def build(attributes)
      self.model_instance ||= (base.kind_of?(Class) ? base.new(attributes) : base.build(attributes))
    end
    
    def model_instance
      @controller.instance_variable_get("@#{@name}")
    end
    
    def model_instance=(instance)
      @controller.instance_variable_set("@#{@name}", instance)
    end
    
    private
    
    # The object that methods (such as "find", "new" or "build") are called on.
    # If there is a parent it will be the association, otherwise it will be the model's class.
    def base
      @parent ? @parent.model_instance.send(@name.to_s.pluralize) : model_class
    end
  end
end
