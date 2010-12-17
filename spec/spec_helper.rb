require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'supermodel' # shouldn't Bundler do this already?
require 'active_support/all'
require 'matchers'
require 'cancan/matchers'
require 'active_record'
require 'with_model'

RSpec.configure do |config|
  config.mock_with :rr
  config.before(:each) do
    Project.delete_all
    Category.delete_all
  end
  config.extend WithModel
end

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")

class Ability
  include CanCan::Ability

  def initialize(user)
  end
end

class Category < SuperModel::Base
  has_many :projects
end

class Project < SuperModel::Base
  belongs_to :category

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
