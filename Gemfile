source "http://rubygems.org"

case ENV["MODEL_ADAPTER"]
when nil, "active_record"
  gem "activerecord", :require => "active_record"
when "data_mapper"
  gem "dm-core", "~> 1.0.2"
when "mongoid"
  gem "bson_ext", "~> 1.1"
  gem "mongoid", "~> 2.0.0.beta.19"
end

gemspec
