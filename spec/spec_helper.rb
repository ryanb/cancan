require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'supermodel' # shouldn't Bundler do this already?
require 'active_support/all'
require 'matchers'
require 'cancan/matchers'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.mock_with :rr
  config.before(:each) do
    Project.delete_all
    Category.delete_all
  end
  config.extend WithModel if ENV["MODEL_ADAPTER"].nil? || ENV["MODEL_ADAPTER"] == "active_record"
end

class Ability
  include CanCan::Ability

  def initialize(user)
  end
end

class Category < SuperModel::Base
  has_many :projects
end

module Sub
  class Project < SuperModel::Base
    belongs_to :category
    attr_accessor :category # why doesn't SuperModel do this automatically?

    def self.respond_to?(method, include_private = false)
      if method.to_s == "find_by_name!" # hack to simulate ActiveRecord
        true
      else
        super
      end
    end
  end
end

class Project < SuperModel::Base
  belongs_to :category
  attr_accessor :category # why doesn't SuperModel do this automatically?

  def self.respond_to?(method, include_private = false)
    if method.to_s == "find_by_name!" # hack to simulate ActiveRecord
      true
    else
      super
    end
  end
end
