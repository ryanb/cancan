module CanCan
  # Handle the load and authorization controller logic so we don't clutter up all controllers with non-interface methods.
  # This class is used internally, so you do not need to call methods directly on it.
  class ControllerResource # :nodoc:
    def self.add_before_filter(controller_class, method, *args)
      options = args.extract_options!
      resource_name = args.first
      controller_class.before_filter(options.slice(:only, :except)) do |controller|
        controller.class.cancan_resource_class.new(controller, resource_name, options.except(:only, :except)).send(method)
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
      if parent? || member_action?
        self.resource_instance ||= load_resource_instance
      elsif load_collection?
        self.collection_instance ||= load_collection
      end
    end

    def authorize_resource
      @controller.authorize!(authorization_action, resource_instance || resource_class_with_parent)
    end

    def parent?
      @options.has_key?(:parent) ? @options[:parent] : @name && @name != name_from_controller.to_sym
    end

    protected

    def load_resource_instance
      if !parent? && new_actions.include?(@params[:action].to_sym)
        build_resource
      elsif id_param || @options[:singleton]
        find_resource
      end
    end

    def load_collection?
      resource_base.respond_to?(:accessible_by) &&
      !current_ability.has_block?(authorization_action, resource_class)
    end

    def load_collection
      resource_base.accessible_by(current_ability)
    end

    def build_resource
      if @options[:singleton] && resource_base.respond_to?("build_#{name}")
        resource = resource_base.send("build_#{name}")
      else
        resource = resource_base.send("new")
      end
      initial_attributes.each do |name, value|
        resource.send("#{name}=", value)
      end
      resource.attributes = @params[name] if @params[name]
      resource
    end

    def initial_attributes
      current_ability.attributes_for(@params[:action].to_sym, resource_class)
    end

    def find_resource
      if @options[:singleton] && resource_base.respond_to?(name)
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

    def resource_class_with_parent
      parent_resource ? {parent_resource => resource_class} : resource_class
    end

    def resource_instance=(instance)
      @controller.instance_variable_set("@#{instance_name}", instance)
    end

    def resource_instance
      @controller.instance_variable_get("@#{instance_name}")
    end

    def collection_instance=(instance)
      @controller.instance_variable_set("@#{instance_name.to_s.pluralize}", instance)
    end

    def collection_instance
      @controller.instance_variable_get("@#{instance_name.to_s.pluralize}")
    end

    # The object that methods (such as "find", "new" or "build") are called on.
    # If the :through option is passed it will go through an association on that instance.
    # If the :shallow option is passed it will use the resource_class if there's no parent
    # If the :singleton option is passed it won't use the association because it needs to be handled later.
    def resource_base
      if @options[:through]
        if parent_resource
          @options[:singleton] ? parent_resource : parent_resource.send(@options[:through_association] || name.to_s.pluralize)
        elsif @options[:shallow]
          resource_class
        else
          raise AccessDenied # maybe this should be a record not found error instead?
        end
      else
        resource_class
      end
    end

    # The object to load this resource through.
    def parent_resource
      @options[:through] && [@options[:through]].flatten.map { |i| fetch_parent(i) }.compact.first
    end

    def fetch_parent(name)
      if @controller.instance_variable_defined? "@#{name}"
        @controller.instance_variable_get("@#{name}")
      elsif @controller.respond_to? name
        @controller.send(name)
      end
    end

    def current_ability
      @controller.send(:current_ability)
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
