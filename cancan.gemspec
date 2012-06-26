Gem::Specification.new do |s|
  s.name        = "cancan"
  s.version     = "2.0.0.alpha"
  s.author      = "Ryan Bates"
  s.email       = "ryan@railscasts.com"
  s.homepage    = "http://github.com/ryanb/cancan"
  s.summary     = "Simple authorization solution for Rails."
  s.description = "Simple authorization solution for Rails which is decoupled from user roles. All permissions are stored in a single location."

  s.files        = Dir["{lib,spec}/**/*", "[A-Z]*", "init.rb"] - ["Gemfile.lock"]
  s.require_path = "lib"

  s.add_development_dependency "rspec", "~> 2.9.0"
  s.add_development_dependency "rails", "~> 3.2.6"
  s.add_development_dependency "sqlite3", "~> 1.3.5"

  s.add_development_dependency "dm-core", "~> 1.2.0"
  s.add_development_dependency "dm-sqlite-adapter", "~> 1.2.0"
  s.add_development_dependency "dm-migrations", "~> 1.2.0"

  s.add_development_dependency "mongoid", "~> 2.4.8"
  s.add_development_dependency "bson_ext", "~> 1.6.2"

  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
end
