module CanCan
  
  # This module is automatically included into all controllers.
  # It also makes the "can?" and "cannot?" methods available to all views.
  module ControllerAdditions
    def self.included(base)
      base.helper_method :can?, :cannot?
    end
    
    # Raises the CanCan::AccessDenied exception. This is often used in a
    # controller action to mark a request as unauthorized.
    # 
    #   def show
    #     @article = Article.find(params[:id])
    #     unauthorized! if cannot? :read, @article
    #   end
    # 
    # You can rescue from the exception in the controller to specify
    # the user experience.
    # 
    #   class ApplicationController < ActionController::Base
    #     rescue_from CanCan::AccessDenied, :with => :access_denied
    #   
    #     protected
    #   
    #     def access_denied
    #       flash[:error] = "Sorry, you are not allowed to access that page."
    #       redirect_to root_url
    #     end
    #   end
    # 
    # See the load_and_authorize_resource method to automatically add
    # the "unauthorized!" behavior to a RESTful controller's actions.
    def unauthorized!
      raise AccessDenied, "You are unable to access this page."
    end
    
    # Creates and returns the current user's ability. You generally do not invoke
    # this method directly, instead you can override this method to change its
    # behavior if the Ability class or current_user method are different.
    # 
    #   def current_ability
    #     UserAbility.new(current_account) # instead of Ability.new(current_user)
    #   end
    # 
    def current_ability
      ::Ability.new(current_user)
    end
    
    # Use in the controller or view to check the user's permission for a given action
    # and object.
    # 
    #   can? :destroy, @project
    # 
    # You can also pass the class instead of an instance (if you don't have one handy).
    # 
    #   <% if can? :create, Project %>
    #     <%= link_to "New Project", new_project_path %>
    #   <% end %>
    # 
    # This simply calls "can?" on the current_ability. See Ability#can?.
    def can?(*args)
      (@current_ability ||= current_ability).can?(*args)
    end
    
    # Convenience method which works the same as "can?" but returns the opposite value.
    # 
    #   cannot? :destroy, @project
    # 
    def cannot?(*args)
      (@current_ability ||= current_ability).cannot?(*args)
    end
    
    # This method loads the appropriate model resource into an instance variable. For example,
    # given an ArticlesController it will load the current article into the @article instance
    # variable. It does this by either calling Article.find(params[:id]) or
    # Article.new(params[:article]) depending upon the action. It does nothing for the "index"
    # action.
    # 
    # You would often use this as a before filter in the controller. See
    # load_and_authorize_resource to handle authorization too.
    # 
    #   before_filter :load_resource
    # 
    def load_resource
      ResourceAuthorization.new(self, params).load_resource
    end
    
    # Authorizes the resource in the current instance variable. For example,
    # if you have an ArticlesController it will check the @article instance variable
    # and ensure the user can perform the current action on it.
    # Under the hood it is doing something like the following.
    # 
    #   unauthorized! if cannot?(params[:action].to_sym, @article || Article)
    # 
    # You would often use this as a before filter in the controller.
    # 
    #   before_filter :authorize_resource
    # 
    # See load_and_authorize_resource to automatically load the resource too.
    def authorize_resource
      ResourceAuthorization.new(self, params).authorize_resource
    end
    
    # Calls load_resource to load the current resource model into an instance variable. 
    # Then calls authorize_resource to ensure the current user is authorized to access the page. 
    # You would often use this as a before filter in the controller.
    # 
    #   before_filter :load_and_authorize_resource
    # 
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
