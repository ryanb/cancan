require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'active_support/all'
require 'matchers'
require 'cancan/matchers'

require File.expand_path('../fixtures/active_record', __FILE__)

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

class Ability
  include CanCan::Ability

  def initialize(user)
  end
end
