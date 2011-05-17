require 'cancan/ability'
require 'cancan/rule'
require 'cancan/controller_resource'
require 'cancan/controller_additions'
require 'cancan/model_additions'
require 'cancan/exceptions'
require 'cancan/inherited_resource'

require 'cancan/model_adapters/abstract_adapter'
require 'cancan/model_adapters/default_adapter'
require 'cancan/model_adapters/active_record_adapter' if defined? ActiveRecord
require 'cancan/model_adapters/data_mapper_adapter' if defined? DataMapper
require 'cancan/model_adapters/mongoid_adapter' if defined?(Mongoid) && defined?(Mongoid::Document)
