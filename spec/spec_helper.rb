require 'rubygems'
require 'spec'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_view'
require File.dirname(__FILE__) + '/../lib/cancan.rb'

Spec::Runner.configure do |config|
  config.mock_with :rr
end

class Ability
  include CanCan::Ability
  
  def initialize(user)
  end
end

# this class helps out in testing nesting
class Person
end
