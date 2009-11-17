module CanCan
  class AccessDenied < StandardError; end
end

require File.dirname(__FILE__) + '/cancan/instance_exec'
require File.dirname(__FILE__) + '/cancan/ability'
require File.dirname(__FILE__) + '/cancan/controller_additions'
