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

  s.add_development_dependency 'rspec', '~> 2.9.0'
  s.add_development_dependency 'rails', '~> 3.2.3'

  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
end
