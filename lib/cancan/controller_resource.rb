module CanCan
  # Handle the load and authorization controller logic so we don't clutter up all controllers with non-interface methods.
  # This class is used internally, so you do not need to call methods directly on it.
  class ControllerResource # :nodoc:
    def self.add_before_filter(controller_class, method, *args)
      options = args.extract_options!
      resource_name = args.first
      controller_class.before_filter(options.slice(:only, :except)) do |controller|
        ControllerResource.new(controller, resource_name, options.except(:only, :except)).send(method)
      end
    end

    def initialize(controller, *args)
      @controller = controller
      @params = controller.params
      @options = args.extract_options!
      @name = args.first
      raise CanCan::ImplementationRemoved, "The :nested option is no longer supported, instead use :through with separate load/authorize call." if @options[:nested]
      raise CanCan::ImplementationRemoved, "The :name option is no longer supported, instead pass the name as the first argument." if @options[:name]
      raise CanCan::ImplementationRemoved, "The :resource option has been renamed back to :class, use false if no class." if @options[:resource]
    end

    def load_and_authorize_resource
      load_resource
      authorize_resource
    end

    def load_resource
      if !resource_instance && (parent? || member_action?)
        @controller.instance_variable_set("@#{instance_name}", load_resource_instance)
      end
    end

    def authorize_resource
      @controller.authorize!(authorization_action, resource_instance || resource_class)
    end

    def parent?
      @options.has_key?(:parent) ? @options[:parent] : @name && @name != name_from_controller.to_sym
    end

    private

    def load_resource_instance
      if !parent? && new_actions.include?(@params[:action].to_sym)
        build_resource
      elsif id_param || @options[:singleton]
        find_resource
      end
    end

    def build_resource
      method_name = @options[:singleton] ? "build_#{name}" : "new"
      resource_base.send(*[method_name, @params[name]].compact)
    end

    def find_resource
      if @options[:singleton]
        resource_base.send(name)
      else
        @options[:find_by] ? resource_base.send("find_by_#{@options[:find_by]}!", id_param) : resource_base.find(id_param)
      end
    end

    def authorization_action
      parent? ? :read : @params[:action].to_sym
    end

    def id_param
      @params[parent? ? :"#{name}_id" : :id]
    end

    def member_action?
      !collection_actions.include? @params[:action].to_sym
    end

    # Returns the class used for this resource. This can be overriden by the :class option.
    # If +false+ is passed in it will use the resource name as a symbol in which case it should
    # only be used for authorization, not loading since there's no class to load through.
    def resource_class
      case @options[:class]
      when false  then name.to_sym
      when nil    then name.to_s.camelize.constantize
      when String then @options[:class].constantize
      else @options[:class]
      end
    end

    def resource_instance
      @controller.instance_variable_get("@#{instance_name}")
    end

    # The object that methods (such as "find", "new" or "build") are called on.
    # If the :through option is passed it will go through an association on that instance.
    # If the :singleton option is passed it won't use the association because it needs to be handled later.
    def resource_base
      if through_resource
        @options[:singleton] ? through_resource : through_resource.send(name.to_s.pluralize)
      else
        resource_class
      end
    end

    # The object to load this resource through.
    def through_resource
      @options[:through] && [@options[:through]].flatten.map { |i| @controller.instance_variable_get("@#{i}") }.compact.first
    end

    def name
      @name || name_from_controller
    end

    def name_from_controller
      @params[:controller].sub("Controller", "").underscore.split('/').last.singularize
    end

    def instance_name
      @options[:instance_name] || name
    end

    def collection_actions
      [:index] + [@options[:collection]].flatten
    end

    def new_actions
      [:new, :create] + [@options[:new]].flatten
    end
  end
end
