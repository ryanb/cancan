module CanCan
  # Handle the load and authorization controller logic so we don't clutter up all controllers with non-interface methods.
  # This class is used internally, so you do not need to call methods directly on it.
  class ResourceAuthorization # :nodoc:
    def self.add_before_filter(controller_class, method, options = {})
      controller_class.before_filter(options.slice(:only, :except)) do |controller|
        ResourceAuthorization.new(controller, controller.params, options.except(:only, :except)).send(method)
      end
    end

    def initialize(controller, params, options = {})
      @controller = controller
      @params = params
      @options = options
    end

    def load_and_authorize_resource
      load_resource
      authorize_resource
    end

    def load_resource
      if collection_actions.include? @params[:action].to_sym
        parent_resource
      else
        if new_actions.include? @params[:action].to_sym
          resource.build(@params[model_name.to_sym])
        elsif @params[:id]
          resource.find(@params[:id])
        end
      end
    end

    def authorize_resource
      @controller.authorize!(@params[:action].to_sym, resource.model_instance || resource.model_class)
    end

    private

    def resource
      @resource ||= ControllerResource.new(@controller, model_name, parent_resource, @options)
    end

    def parent_resource
      parent = nil
      [@options[:nested]].flatten.compact.each do |name|
        id = @params["#{name}_id".to_sym]
        if id
          parent = ControllerResource.new(@controller, name, parent)
          parent.find(id)
        else
          parent = nil
        end
      end
      parent
    end

    def model_name
      @options[:name] || @params[:controller].sub("Controller", "").underscore.split('/').last.singularize
    end

    def collection_actions
      [:index] + [@options[:collection]].flatten
    end

    def new_actions
      [:new, :create] + [@options[:new]].flatten
    end
  end
end
