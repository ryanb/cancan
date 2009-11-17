module CanCan
  module ControllerAdditions
    def self.included(base)
      base.helper_method :can?
    end
    
    def unauthorized!
      raise AccessDenied, "You are unable to access this page."
    end
    
    def current_ability
      ::Ability.for_user(current_user)
    end
    
    def can?(*args)
      (@current_ability ||= current_ability).can?(*args)
    end
  end
end

class ActionController::Base
  include CanCan::ControllerAdditions
end
