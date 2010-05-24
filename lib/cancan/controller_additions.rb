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
        ResourceAuthorization.add_before_filter(self, :load_and_authorize_resource, options)
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
      # [:+name+]
      #   The name of the resource if it cannot be determined from controller (string or symbol).
      #
      #     load_resource :name => :article
      #
      # [:+resource+]
      #   The class to use for the model (string or constant).
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
        ResourceAuthorization.add_before_filter(self, :load_resource, options)
      end

      # Sets up a before filter which authorizes the current resource using the instance variable.
      # For example, if you have an ArticlesController it will check the @article instance variable
      # and ensure the user can perform the current action on it. Under the hood it is doing
      # something like the following.
      #
      #   authorize!(params[:action].to_sym, @article || Article)
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
      # [:+name+]
      #   The name of the resource if it cannot be determined from controller (string or symbol).
      #
      #     load_resource :name => :article
      #
      # [:+resource+]
      #   The class to use for the model (string or constant). Alternatively pass a symbol
      #   to represent a resource which does not have a class.
      #
      def authorize_resource(options = {})
        ResourceAuthorization.add_before_filter(self, :authorize_resource, options)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.helper_method :can?, :cannot?
    end

    # Raises a CanCan::AccessDenied exception if the current_ability cannot
    # perform the given action. This is usually called in a controller action or
    # before filter to perform the authorization.
    #
    #   def show
    #     @article = Article.find(params[:id])
    #     authorize! :read, @article
    #   end
    #
    # A :message option can be passed to specify a different message.
    #
    #   authorize! :read, @article, :message => "Not authorized to read #{@article.name}"
    #
    # You can rescue from the exception in the controller to customize how unauthorized
    # access is displayed to the user.
    #
    #   class ApplicationController < ActionController::Base
    #     rescue_from CanCan::AccessDenied do |exception|
    #       flash[:error] = exception.message
    #       redirect_to root_url
    #     end
    #   end
    #
    # See the CanCan::AccessDenied exception for more details on working with the exception.
    #
    # See the load_and_authorize_resource method to automatically add the authorize! behavior
    # to the default RESTful actions.
    def authorize!(action, subject, *args)
      message = nil
      if args.last.kind_of?(Hash) && args.last.has_key?(:message)
        message = args.pop[:message]
      end
      raise AccessDenied.new(message, action, subject) if cannot?(action, subject, *args)
    end

    def unauthorized!(message = nil)
      raise ImplementationRemoved, "The unauthorized! method has been removed from CanCan, use authorize! instead."
    end

    # Creates and returns the current user's ability and caches it. If you
    # want to override how the Ability is defined then this is the place.
    # Just define the method in the controller to change behavior.
    #
    #   def current_ability
    #     # instead of Ability.new(current_user)
    #     @current_ability ||= UserAbility.new(current_account)
    #   end
    #
    # Notice it is important to cache the ability object so it is not
    # recreated every time.
    def current_ability
      @current_ability ||= ::Ability.new(current_user)
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
      current_ability.can?(*args)
    end

    # Convenience method which works the same as "can?" but returns the opposite value.
    #
    #   cannot? :destroy, @project
    #
    def cannot?(*args)
      current_ability.cannot?(*args)
    end
  end
end

if defined? ActionController
  ActionController::Base.class_eval do
    include CanCan::ControllerAdditions
  end
end
