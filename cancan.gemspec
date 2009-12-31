Gem::Specification.new do |s|
  s.name = "cancan"
  s.summary = "Simple authorization solution for Rails."
  s.description = "Simple authorization solution for Rails which is completely decoupled from the user's roles. All permissions are stored in a single location for convenience."
  s.homepage = "http://github.com/ryanb/cancan"
  
  s.version = "1.0.2"
  s.date = "2009-12-30"
  
  s.authors = ["Ryan Bates"]
  s.email = "ryan@railscasts.com"
  
  s.require_paths = ["lib"]
  s.files = Dir["lib/**/*"] + Dir["spec/**/*"] + ["LICENSE", "README.rdoc", "Rakefile", "CHANGELOG.rdoc", "init.rb"]
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG.rdoc", "LICENSE"]
  
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "CanCan", "--main", "README.rdoc"]
  
  s.rubygems_version = "1.3.4"
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2")
end
