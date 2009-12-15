module CanCan
  
  # This module is automatically included into all controllers.
  # It also makes the "can?" and "cannot?" methods available to all views.
  module ControllerAdditions
    module ClassMethods
      # Sets up a before filter which loads and authorizes the current resource. This performs both
      # load_resource and authorize_resource and accepts the same arguments. See those methods for details.
      # 
      #   class BooksController < ApplicationController
      #     load_and_authorize_resource
      #   end
      # 
      def load_and_authorize_resource(options = {})
        before_filter(options.slice(:only, :except)) { |c| ResourceAuthorization.new(c, c.params, options.except(:only, :except)).load_and_authorize_resource }
      end
      
      # Sets up a before filter which loads the appropriate model resource into an instance variable.
      # For example, given an ArticlesController it will load the current article into the @article
      # instance variable. It does this by either calling Article.find(params[:id]) or
      # Article.new(params[:article]) depending upon the action. It does nothing for the "index"
      # action.
      # 
      # Call this method directly on the controller class.
      # 
      #   class BooksController < ApplicationController
      #     load_resource
      #   end
      # 
      # A resource is not loaded if the instance variable is already set. This makes it easy to override
      # the behavior through a before_filter on certain actions.
      # 
      #   class BooksController < ApplicationController
      #     before_filter :find_book_by_permalink, :only => :show
      #     load_resource
      #
      #     private
      #
      #     def find_book_by_permalink
      #       @book = Book.find_by_permalink!(params[:id)
      #     end
      #   end
      # 
      # See load_and_authorize_resource to automatically authorize the resource too.
      # 
      # Options:
      # [:+only+]
      #   Only applies before filter to given actions.
      #   
      # [:+except+]
      #   Does not apply before filter to given actions.
      #   
      # [:+nested+]
      #   Specify which resource this is nested under.
      #   
      #     load_resource :nested => :author
      #   
      #   Deep nesting can be defined in an array.
      #   
      #     load_resource :nested => [:publisher, :author]
      #   
      # [:+class+]
      #   The class to use for the model.
      #   
      # [:+collection+]
      #   Specify which actions are resource collection actions in addition to :+index+. This
      #   is usually not necessary because it will try to guess depending on if an :+id+
      #   is present in +params+.
      #   
      #     load_resource :collection => [:sort, :list]
      #   
      # [:+new+]
      #   Specify which actions are new resource actions in addition to :+new+ and :+create+.
      #   Pass an action name into here if you would like to build a new resource instead of
      #   fetch one.
      #   
      #     load_resource :new => :build
      # 
      def load_resource(options = {})
        before_filter(options.slice(:only, :except)) { |c| ResourceAuthorization.new(c, c.params, options.except(:only, :except)).load_resource }
      end
      
      # Sets up a before filter which authorizes the current resource using the instance variable.
      # For example, if you have an ArticlesController it will check the @article instance variable
      # and ensure the user can perform the current action on it. Under the hood it is doing
      # something like the following.
      # 
      #   unauthorized! if cannot?(params[:action].to_sym, @article || Article)
      # 
      # Call this method directly on the controller class.
      # 
      #   class BooksController < ApplicationController
      #     authorize_resource
      #   end
      # 
      # See load_and_authorize_resource to automatically load the resource too.
      # 
      # Options:
      # [:+only+]
      #   Only applies before filter to given actions.
      #   
      # [:+except+]
      #   Does not apply before filter to given actions.
      # 
      # [:+class+]
      #   The class to use for the model.
      # 
      def authorize_resource(options = {})
        before_filter(options.slice(:only, :except)) { |c| ResourceAuthorization.new(c, c.params, options.except(:only, :except)).authorize_resource }
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
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
    # The unauthorized! method accepts an optional argument which sets the
    # message of the exception.
    # 
    # You can rescue from the exception in the controller to define the behavior.
    # 
    #   class ApplicationController < ActionController::Base
    #     rescue_from CanCan::AccessDenied do |exception|
    #       flash[:error] = exception.message
    #       redirect_to root_url
    #     end
    #   end
    # 
    # See the load_and_authorize_resource method to automatically add
    # the "unauthorized!" behavior to a RESTful controller's actions.
    def unauthorized!(message = "You are not authorized to access this page.")
      raise AccessDenied, message
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
  end
end

if defined? ActionController
  ActionController::Base.class_eval do
    include CanCan::ControllerAdditions
  end
end
