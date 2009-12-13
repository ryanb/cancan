module CanCan
  class ResourceAuthorization # :nodoc:
    attr_reader :params
    
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
      unless collection_actions.include? params[:action].to_sym
        if new_actions.include? params[:action].to_sym
          self.model_instance = model_class.new(params[model_name.to_sym])
        else
          self.model_instance = model_class.find(params[:id]) if params[:id]
        end
      end
    end
    
    def authorize_resource
      @controller.unauthorized! if @controller.cannot?(params[:action].to_sym, model_instance || model_class)
    end
    
    private
    
    def model_name
      params[:controller].split('/').last.singularize
    end
    
    def model_class
      model_name.camelcase.constantize
    end
    
    def model_instance
      @controller.instance_variable_get("@#{model_name}")
    end
    
    def model_instance=(instance)
      @controller.instance_variable_set("@#{model_name}", instance)
    end
    
    def collection_actions
      [:index] + [@options[:collection]].flatten
    end
    
    def new_actions
      [:new, :create] + [@options[:new]].flatten
    end
  end
end
