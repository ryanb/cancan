require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'supermodel' # shouldn't Bundler do this already?
require 'active_support/all'
require 'matchers'
require 'cancan/matchers'

RSpec.configure do |config|
  config.mock_with :rr
  config.before(:each) do
    Project.delete_all
    Category.delete_all
  end
end

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
  attr_accessor :category # why doesn't SuperModel do this automatically?
end
