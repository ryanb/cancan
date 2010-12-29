source "http://rubygems.org"
gemspec

case ENV["MODEL_ADAPTER"]
when "mongoid"
  gem "bson_ext", "~> 1.1"
  gem "mongoid", "~> 2.0.0.beta.19"
when "data_mapper"
  gem "dm-core", "~> 1.0.2"
end
