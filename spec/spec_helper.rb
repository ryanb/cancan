require 'rubygems'
require 'spec'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_view'
require 'matchers'
require 'cancan'
require 'cancan/matchers'

Spec::Runner.configure do |config|
  config.mock_with :rr
end

class Ability
  include CanCan::Ability

  def initialize(user)
  end
end

# this class helps out in testing SQL conditions
class Person
  class << self
    protected

    def sanitize_sql(hash_cond)
      case hash_cond
      when Hash
        sanitize_hash(hash_cond).join(' AND ')
      when Array
        hash_cond.shift.gsub('?'){"#{hash_cond.shift.inspect}"}
      when String then hash_cond
      end
    end

    def sanitize_hash(hash)
      hash.map do |name, value|
        if Hash === value
          sanitize_hash(value).map{|cond| "#{name}.#{cond}"}
        else
          "#{name}=#{value}"
        end
      end.flatten
    end
  end
end
