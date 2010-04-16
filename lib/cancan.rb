module CanCan
  # A general CanCan exception
  class Error < StandardError; end
  
  # This error is raised when a user isn't allowed to access a given
  # controller action. See ControllerAdditions#unauthorized! for details.
  class AccessDenied < Error; end
end

require 'cancan/ability'
require 'cancan/controller_resource'
require 'cancan/resource_authorization'
require 'cancan/controller_additions'
require 'cancan/active_record_additions'
