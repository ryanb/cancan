require 'rubygems'
require 'bundler/setup'

require "sqlite3"
require "active_record"

case ENV["MODEL_ADAPTER"]
when "data_mapper"
  require "dm-core"
  require "dm-sqlite-adapter"
  require "dm-migrations"
when "mongoid"
  require "mongoid"
end

require 'active_support/all'
require 'matchers'
require 'cancan'
require 'cancan/matchers'

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

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

class Category < ActiveRecord::Base
  connection.create_table(table_name) do |t|
    t.boolean :visible
  end
  has_many :projects
end

class Project < ActiveRecord::Base
  connection.create_table(table_name) do |t|
    t.integer :category_id
    t.string :name
  end
  belongs_to :category
end
