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
      def load_and_authorize_resource(*args)
        cancan_resource_class.add_before_filter(self, {:load => true, :authorize => true}, *args)
      end

      # Sets up a before filter which loads the model resource into an instance variable.
      # For example, given an ArticlesController it will load the current article into the @article
      # instance variable. It does this by either calling Article.find(params[:id]) or
      # Article.new(params[:article]) depending upon the action. The index action will
      # automatically set @articles to Article.accessible_by(current_ability).
      #
      # If a conditions hash is used in the Ability, the +new+ and +create+ actions will set
      # the initial attributes based on these conditions. This way these actions will satisfy
      # the ability restrictions.
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
      # If a name is provided which does not match the controller it assumes it is a parent resource. Child
      # resources can then be loaded through it.
      #
      #   class BooksController < ApplicationController
      #     load_resource :author
      #     load_resource :book, :through => :author
      #   end
      #
      # Here the author resource will be loaded before each action using params[:author_id]. The book resource
      # will then be loaded through the @author instance variable.
      #
      # That first argument is optional and will default to the singular name of the controller.
      # A hash of options (see below) can also be passed to this method to further customize it.
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
      # [:+through+]
      #   Load this resource through another one. This should match the name of the parent instance variable or method.
      #
      # [:+through_association+]
      #   The name of the association to fetch the child records through the parent resource. This is normally not needed
      #   because it defaults to the pluralized resource name.
      #
      # [:+shallow+]
      #   Pass +true+ to allow this resource to be loaded directly when parent is +nil+. Defaults to +false+.
      #
      # [:+singleton+]
      #   Pass +true+ if this is a singleton resource through a +has_one+ association.
      #
      # [:+parent+]
      #   True or false depending on if the resource is considered a parent resource. This defaults to +true+ if a resource
      #   name is given which does not match the controller.
      #
      # [:+class+]
      #   The class to use for the model (string or constant).
      #
      # [:+instance_name+]
      #   The name of the instance variable to load the resource into.
      #
      # [:+find_by+]
      #   Find using a different attribute other than id. For example.
      #
      #     load_resource :find_by => :permalink # will use find_by_permalink!(params[:id])
      #
      # [:+collection+]
      #   Specify which actions are resource collection actions in addition to :+index+. This
      #   is usually not necessary because it will try to guess depending on if the id param is present.
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
      # [:+prepend+]
      #   Passing +true+ will use prepend_before_filter instead of a normal before_filter.
      #
      def load_resource(*args)
        raise ImplementationRemoved, "The load_resource method has been removed, use load_and_authorize_resource instead."
        cancan_resource_class.add_before_filter(self, {:load => true}, *args)
      end

      # Sets up a before filter which authorizes the resource using the instance variable.
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
      # If you pass in the name of a resource which does not match the controller it will assume
      # it is a parent resource.
      #
      #   class BooksController < ApplicationController
      #     authorize_resource :author
      #     authorize_resource :book
      #   end
      #
      # Here it will authorize :+show+, @+author+ on every action before authorizing the book.
      #
      # That first argument is optional and will default to the singular name of the controller.
      # A hash of options (see below) can also be passed to this method to further customize it.
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
      # [:+singleton+]
      #   Pass +true+ if this is a singleton resource through a +has_one+ association.
      #
      # [:+parent+]
      #   True or false depending on if the resource is considered a parent resource. This defaults to +true+ if a resource
      #   name is given which does not match the controller.
      #
      # [:+class+]
      #   The class to use for the model (string or constant). This passed in when the instance variable is not set.
      #   Pass +false+ if there is no associated class for this resource and it will use a symbol of the resource name.
      #
      # [:+instance_name+]
      #   The name of the instance variable for this resource.
      #
      # [:+through+]
      #   Authorize conditions on this parent resource when instance isn't available.
      #
      # [:+prepend+]
      #   Passing +true+ will use prepend_before_filter instead of a normal before_filter.
      #
      def authorize_resource(*args)
        raise ImplementationRemoved, "The authorize_resource method has been removed, use load_and_authorize_resource instead."
        cancan_resource_class.add_before_filter(self, {:authorize => true}, *args)
      end

      # Skip both the loading and authorization behavior of CanCan for this given controller. This is primarily
      # useful to skip the behavior of a superclass. You can pass :only and :except options to specify which actions
      # to skip the effects on. It will apply to all actions by default.
      #
      #   class ProjectsController < SomeOtherController
      #     skip_load_and_authorize_resource :only => :index
      #   end
      #
      # You can also pass the resource name as the first argument to skip that resource.
      def skip_load_and_authorize_resource(*args)
        skip_load_resource(*args)
        skip_authorize_resource(*args)
      end

      # Skip the loading behavior of CanCan. This is useful when using +load_and_authorize_resource+ but want to
      # only do authorization on certain actions. You can pass :only and :except options to specify which actions to
      # skip the effects on. It will apply to all actions by default.
      #
      #   class ProjectsController < ApplicationController
      #     load_and_authorize_resource
      #     skip_load_resource :only => :index
      #   end
      #
      # You can also pass the resource name as the first argument to skip that resource.
      def skip_load_resource(*args)
        raise ImplementationRemoved, "The skip_load_resource method has been removed, use skip_load_and_authorize_resource instead."
        options = args.extract_options!
        name = args.first
        cancan_skipper[:load][name] = options
      end

      # Skip the authorization behavior of CanCan. This is useful when using +load_and_authorize_resource+ but want to
      # only do loading on certain actions. You can pass :only and :except options to specify which actions to
      # skip the effects on. It will apply to all actions by default.
      #
      #   class ProjectsController < ApplicationController
      #     load_and_authorize_resource
      #     skip_authorize_resource :only => :index
      #   end
      #
      # You can also pass the resource name as the first argument to skip that resource.
      def skip_authorize_resource(*args)
        raise ImplementationRemoved, "The skip_authorize_resource method has been removed, use skip_load_and_authorize_resource instead."
        options = args.extract_options!
        name = args.first
        cancan_skipper[:authorize][name] = options
      end

      # Add this to a controller to automatically perform authorization on every action.
      #
      #   class ApplicationController < ActionController::Base
      #     enable_authorization
      #   end
      #
      # Internally it does this in a before_filter for every action.
      #
      #   authorize! params[:action], params[:controller]
      #
      # If you need to "skip" authorization in a given controller, it is best to enable :+access+ to it in the +Ability+.
      #
      # Options:
      # [:+only+]
      #   Only applies to given actions.
      #
      # [:+except+]
      #   Does not apply to given actions.
      #
      # [:+if+]
      #   Supply the name of a controller method to be called. The authorization only takes place if this returns true.
      #
      #     enable_authorization :if => :admin_controller?
      #
      # [:+unless+]
      #   Supply the name of a controller method to be called. The authorization only takes place if this returns false.
      #
      #     enable_authorization :unless => :devise_controller?
      #
      def enable_authorization(options = {}, &block)
        before_filter(options.slice(:only, :except)) do |controller|
          break if options[:if] && !controller.send(options[:if])
          break if options[:unless] && controller.send(options[:unless])
          controller.authorize! controller.params[:action], controller.params[:controller]
        end
        after_filter(options.slice(:only, :except)) do |controller|
          break if options[:if] && !controller.send(options[:if])
          break if options[:unless] && controller.send(options[:unless])
          unless controller.current_ability.fully_authorized? controller.params[:action], controller.params[:controller]
            # https://github.com/ryanb/cancan/issues/699
            #raise CanCan::InsufficientAuthorizationCheck, "Authorization check is not sufficient for this action. This is probably because you have conditions or attributes defined in Ability and are not checking for them in the action. One way to solve this is adding load_and_authorize_resource to this controller."
          end
        end
        rescue_from(CanCan::Unauthorized, &block) if block
      end

      def cancan_resource_class
        if ancestors.map(&:to_s).include? "InheritedResources::Actions"
          InheritedResource
        else
          ControllerResource
        end
      end

      def check_authorization(options = {})
        raise ImplementationRemoved, "The check_authorization method has been removed, use enable_authorization instead."
      end

      def skip_authorization_check(*args)
        raise ImplementationRemoved, "The skip_authorization_check method has been removed, instead authorize access to controller in Ability to 'skip'."
      end

      def cancan_skipper
        raise ImplementationRemoved, "The skip_authorization_check method has been removed, instead authorize access to controller in Ability to 'skip'."
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.helper_method :can?, :cannot?, :current_ability
    end

    # Raises a CanCan::Unauthorized exception if the current_ability cannot
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
    # You can also use I18n to customize the message. Action aliases defined in Ability work here.
    #
    #   en:
    #     unauthorized:
    #       manage:
    #         all: "Not authorized to %{action} %{subject}."
    #         user: "Not allowed to manage other user accounts."
    #       update:
    #         project: "Not allowed to update this project."
    #
    # You can rescue from the exception in the controller to customize how unauthorized
    # access is displayed to the user.
    #
    #   class ApplicationController < ActionController::Base
    #     rescue_from CanCan::Unauthorized do |exception|
    #       redirect_to root_url, :alert => exception.message
    #     end
    #   end
    #
    # See the CanCan::Unauthorized exception for more details on working with the exception.
    #
    # See the load_and_authorize_resource method to automatically add the authorize! behavior
    # to the default RESTful actions.
    def authorize!(*args)
      @_authorized = true
      current_ability.authorize!(*args)
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
    # If it's a nested resource, you can pass the parent instance in a hash. This way it will
    # check conditions which reach through that association.
    #
    #   <% if can? :create, @category => Project %>
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

if defined? ActionController::Base
  ActionController::Base.class_eval do
    include CanCan::ControllerAdditions
  end
end
