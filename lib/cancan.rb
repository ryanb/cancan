module CanCan
  # This error is raised when a user isn't allowed to access a given
  # controller action. See ControllerAdditions#unauthorized! for details.
  class AccessDenied < StandardError; end
end

require File.dirname(__FILE__) + '/cancan/ability'
require File.dirname(__FILE__) + '/cancan/controller_resource'
require File.dirname(__FILE__) + '/cancan/resource_authorization'
require File.dirname(__FILE__) + '/cancan/controller_additions'
