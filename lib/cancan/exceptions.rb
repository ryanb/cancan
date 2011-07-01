module CanCan
  # A general CanCan exception
  class Error < StandardError; end

  # Raised when behavior is not implemented, usually used in an abstract class.
  class NotImplemented < Error; end

  # Raised when removed code is called, an alternative solution is provided in message.
  class ImplementationRemoved < Error; end

  # Raised when using check_authorization without calling authorized!
  class AuthorizationNotPerformed < Error; end

  # This error is raised when a user isn't allowed to access a given controller action.
  # This usually happens within a call to ControllerAdditions#authorize! but can be
  # raised manually.
  #
  #   raise CanCan::AccessDenied.new("Not authorized!", :read, Article)
  #
  # The passed message, action, and subject are optional and can later be retrieved when
  # rescuing from the exception.
  #
  #   exception.message # => "Not authorized!"
  #   exception.action # => :read
  #   exception.subject # => Article
  #
  # If the message is not specified (or is nil) it will default to "You are not authorized
  # to access this page." This default can be overridden by setting default_message.
  #
  #   exception.default_message = "Default error message"
  #   exception.message # => "Default error message"
  #
  # See ControllerAdditions#authorized! for more information on rescuing from this exception
  # and customizing the message using I18n.
  class AccessDenied < Error
    attr_reader :action, :subject
    attr_writer :default_message

    def initialize(message = nil, action = nil, subject = nil)
      @message = message
      @action = action
      @subject = subject
      @default_message = I18n.t(:"unauthorized.default", :default => "You are not authorized to access this page.")
    end

    def to_s
      @message || @default_message
    end
  end
end
