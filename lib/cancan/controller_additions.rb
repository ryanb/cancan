module CanCan
  module ControllerAdditions
    def self.included(base)
      base.helper_method :can?, :cannot?
    end
    
    def unauthorized!
      raise AccessDenied, "You are unable to access this page."
    end
    
    def current_ability
      ::Ability.new(current_user)
    end
    
    def can?(*args)
      (@current_ability ||= current_ability).can?(*args)
    end
    
    def cannot?(*args)
      (@current_ability ||= current_ability).cannot?(*args)
    end
    
    def load_resource # TODO this could use some refactoring
      model_name = params[:controller].split('/').last.singularize
      unless params[:action] == "index"
        if params[:id]
          instance_variable_set("@#{model_name}", model_name.camelcase.constantize.find(params[:id]))
        else
          instance_variable_set("@#{model_name}", model_name.camelcase.constantize.new(params[model_name.to_sym]))
        end
      end
    end
    
    def authorize_resource # TODO this could use some refactoring
      model_name = params[:controller].split('/').last.singularize
      unauthorized! unless can?(params[:action].to_sym, instance_variable_get("@#{model_name}") || model_name.camelcase.constantize)
    end
    
    def load_and_authorize_resource
      load_resource
      authorize_resource
    end
  end
end

if defined? ActionController
  ActionController::Base.class_eval do
    include CanCan::ControllerAdditions
  end
end
