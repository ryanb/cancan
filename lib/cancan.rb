$:.unshift(File.dirname(__FILE__))
require 'cancan/instance_exec'
require 'cancan/ability'
require 'cancan/controller_additions'

module CanCan
  class AccessDenied < StandardError; end
end