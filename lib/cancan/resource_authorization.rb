module CanCan
  class ResourceAuthorization # :nodoc:
    attr_reader :params
    
    def initialize(controller, params)
      @controller = controller
      @params = params
    end
    
    def load_and_authorize_resource
      load_resource
      authorize_resource
    end
    
    def load_resource
      self.model_instance = params[:id] ? model_class.find(params[:id]) : model_class.new(params[model_name.to_sym]) unless params[:action] == "index"
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
  end
end
