module CanCan
  # Handle the load and authorization controller logic so we don't clutter up all controllers with non-interface methods.
  # This class is used internally, so you do not need to call methods directly on it.
  class ControllerResource # :nodoc:
    def self.add_before_filter(controller_class, behavior, *args)
      options = args.extract_options!.merge(behavior)
      resource_name = args.first
      before_filter_method = options.delete(:prepend) ? :prepend_before_filter : :before_filter
      controller_class.send(before_filter_method, options.slice(:only, :except, :if, :unless)) do |controller|
        controller.class.cancan_resource_class.new(controller, resource_name, options.except(:only, :except, :if, :unless)).process
      end
    end

    def initialize(controller, *args)
      @controller = controller
      @params = controller.params
      @options = args.extract_options!
      @name = args.first
    end

    def process
      if @options[:load]
        if load_instance?
          self.resource_instance ||= load_resource_instance
        elsif load_collection?
          self.collection_instance ||= load_collection
          current_ability.fully_authorized! @params[:action], @params[:controller]
        end
      end
      if @options[:authorize]
        if resource_instance
          if resource_params && (authorization_action == :create || authorization_action == :update)
            resource_params.each do |key, value|
              @controller.authorize!(authorization_action, resource_instance, key.to_sym)
            end
          else
            @controller.authorize!(authorization_action, resource_instance)
          end
        end
      end
    end

    def parent?
      @options.has_key?(:parent) ? @options[:parent] : @name && @name != name_from_controller.to_sym
    end

    # def skip?(behavior) # This could probably use some refactoring
    #   options = @controller.class.cancan_skipper[behavior][@name]
    #   if options.nil?
    #     false
    #   elsif options == {}
    #     true
    #   elsif options[:except] && ![options[:except]].flatten.include?(@params[:action].to_sym)
    #     true
    #   elsif [options[:only]].flatten.include?(@params[:action].to_sym)
    #     true
    #   end
    # end

    protected

    def load_resource_instance
      if !parent? && new_actions.include?(@params[:action].to_sym)
        build_resource
      elsif id_param || @options[:singleton]
        find_and_update_resource
      end
    end

    def load_instance?
      parent? || member_action?
    end

    def load_collection?
      resource_base.respond_to?(:accessible_by) && !current_ability.has_block?(authorization_action, subject_name)
    end

    def load_collection
      resource_base.accessible_by(current_ability, authorization_action)
    end

    def build_resource
      resource = resource_base.new(resource_params || {})
      assign_attributes(resource)
    end

    def assign_attributes(resource)
      resource.send("#{parent_name}=", parent_resource) if @options[:singleton] && parent_resource
      initial_attributes.each do |attr_name, value|
        resource.send("#{attr_name}=", value)
      end
      resource
    end

    def initial_attributes
      current_ability.attributes_for(@params[:action].to_sym, subject_name).delete_if do |key, value|
        resource_params && resource_params.include?(key)
      end
    end

    def find_and_update_resource
      resource = find_resource
      if resource_params
        @controller.authorize!(authorization_action, resource) if @options[:authorize]
        resource.attributes = resource_params
      end
      resource
    end

    def find_resource
      if @options[:singleton] && parent_resource.respond_to?(name)
        parent_resource.send(name)
      else
        if @options[:find_by]
          if resource_base.respond_to? "find_by_#{@options[:find_by]}!"
            resource_base.send("find_by_#{@options[:find_by]}!", id_param)
          else
            resource_base.send(@options[:find_by], id_param)
          end
        else
          adapter.find(resource_base, id_param)
        end
      end
    end

    def adapter
      ModelAdapters::AbstractAdapter.adapter_class(resource_class)
    end

    def authorization_action
      parent? ? :show : @params[:action].to_sym
    end

    def id_param
      if @options[:id_param]
        @params[@options[:id_param]]
      else
        @params[parent? ? :"#{name}_id" : :id]
      end
    end

    def member_action?
      new_actions.include?(@params[:action].to_sym) || @options[:singleton] || ( (@params[:id] || @params[@options[:id_param]]) && !collection_actions.include?(@params[:action].to_sym))
    end

    # Returns the class used for this resource. This can be overriden by the :class option.
    # If +false+ is passed in it will use the resource name as a symbol in which case it should
    # only be used for authorization, not loading since there's no class to load through.
    def resource_class
      case @options[:class]
      when false  then name.to_sym
      when nil    then namespaced_name.to_s.camelize.constantize
      when String then @options[:class].constantize
      else @options[:class]
      end
    end

    def subject_name
      resource_class.to_s.underscore.pluralize.to_sym
    end

    def subject_name_with_parent
      parent_resource ? {parent_resource => subject_name} : subject_name
    end

    def resource_instance=(instance)
      @controller.instance_variable_set("@#{instance_name}", instance)
    end

    def resource_instance
      if load_instance?
        if @controller.instance_variable_defined? "@#{instance_name}"
          @controller.instance_variable_get("@#{instance_name}")
        elsif @controller.respond_to?(instance_name, true)
          @controller.send(instance_name)
        end
      end
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
          @options[:singleton] ? resource_class : parent_resource.send(@options[:through_association] || name.to_s.pluralize)
        elsif @options[:shallow]
          resource_class
        else
          raise Unauthorized.new(nil, authorization_action, @params[:controller].to_sym) # maybe this should be a record not found error instead?
        end
      else
        resource_class
      end
    end

    def parent_name
      @options[:through] && [@options[:through]].flatten.detect { |i| fetch_parent(i) }
    end

    # The object to load this resource through.
    def parent_resource
      parent_name && fetch_parent(parent_name)
    end

    def fetch_parent(name)
      if @controller.instance_variable_defined? "@#{name}"
        @controller.instance_variable_get("@#{name}")
      elsif @controller.respond_to?(name, true)
        @controller.send(name)
      end
    end

    def current_ability
      @controller.send(:current_ability)
    end

    def name
      @name || name_from_controller
    end

    def strong_parameters?
      @params.class.name == 'ActionController::Parameters'
    end

    def resource_params
      if [:create, :update].member? @params[:action].to_sym
        param_name = @options[:instance_name] || (@options[:class] || namespaced_name).to_s.underscore.gsub('/', '_')
        if strong_parameters? || @options[:params]
          params_method = (@options[:params] == true || ! @options[:params]) ?
            "#{param_name}_params" : @options[:params]
          return @controller.send params_method if @controller.send :respond_to?, params_method
        end
        @params[param_name]
      end
    end

    def namespace
      @params[:controller].split(/::|\//)[0..-2]
    end

    def namespaced_name
      [namespace, name.camelize].join('::').singularize.camelize.constantize
    rescue NameError
      name
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
