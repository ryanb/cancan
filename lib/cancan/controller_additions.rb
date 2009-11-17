module CanCan
  module ControllerAdditions
    def self.included(base)
      base.helper_method :can?
    end
    
    def unauthorized!
      raise AccessDenied, "You are unable to access this page."
    end
    
    def current_ability
      ability = ::Ability.new
      ability.prepare(current_user)
      ability
    end
    
    def can?(*args)
      (@current_ability ||= current_ability).can?(*args)
    end
    
    def load_resource # TODO this could use some refactoring
      unless params[:action] == "index"
        if params[:id]
          instance_variable_set("@#{params[:controller].singularize}", params[:controller].singularize.camelcase.constantize.find(params[:id]))
        else
          instance_variable_set("@#{params[:controller].singularize}", params[:controller].singularize.camelcase.constantize.new(params[params[:controller].singularize.to_sym]))
        end
      end
    end
    
    def authorize_resource # TODO this could use some refactoring
      unauthorized! unless can?(params[:action].to_sym, instance_variable_get("@#{params[:controller].singularize}") || params[:controller].singularize.camelcase.constantize)
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