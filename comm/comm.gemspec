$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "comm/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "comm"
  s.version     = Comm::VERSION
  s.authors     = ["stephan koeller"]
  s.email       = ["skoeller@gmx.de"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Comm."
  s.description = "TODO: Description of Comm."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  # s.add_dependency "jquery-rails"
  s.add_dependency "thin"
  #s.add_dependency "resque-scheduler"
  s.add_dependency "faye-rails", "2.0.0"
  s.add_dependency "faye-redis"
  s.add_dependency "haml"
  s.add_dependency "haml-rails"
end
