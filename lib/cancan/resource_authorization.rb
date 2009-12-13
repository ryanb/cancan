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
      load_parent if @options[:nested]
      unless collection_actions.include? params[:action].to_sym
        if new_actions.include? params[:action].to_sym
          if parent_instance
            self.model_instance = parent_instance.send(model_name.pluralize).build(params[model_name.to_sym])
          else
            self.model_instance = model_class.new(params[model_name.to_sym])
          end
        elsif params[:id]
          if parent_instance
            self.model_instance = parent_instance.send(model_name.pluralize).find(params[:id])
          else
            self.model_instance = model_class.find(params[:id])
          end
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
    
    def load_parent
      self.parent_instance = parent_class.find(parent_id)
    end
    
    def parent_class
      @options[:nested].to_s.camelcase.constantize
    end
    
    def parent_id
      @params["#{@options[:nested]}_id".to_sym]
    end
    
    def model_instance
      @controller.instance_variable_get("@#{model_name}")
    end
    
    def model_instance=(instance)
      @controller.instance_variable_set("@#{model_name}", instance)
    end
    
    def parent_instance
      @controller.instance_variable_get("@#{@options[:nested]}")
    end
    
    def parent_instance=(instance)
      @controller.instance_variable_set("@#{@options[:nested]}", instance)
    end
    
    def collection_actions
      [:index] + [@options[:collection]].flatten
    end
    
    def new_actions
      [:new, :create] + [@options[:new]].flatten
    end
  end
end
