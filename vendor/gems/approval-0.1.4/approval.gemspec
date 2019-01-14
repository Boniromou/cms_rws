$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem"s version:
require "approval/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "approval"
  s.version     = Approval::VERSION
  s.authors     = ["Xiaopan Yun"]
  s.email       = ["xiaopan.yun@laxino.com"]
  s.homepage    = ""
  s.summary     = "Second Approval."
  s.description = "Rails engine for Second Approval."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_development_dependency "rspec-rails", "~> 3.0.2"
  s.add_development_dependency "capybara", "~> 2.4.3"
  s.add_development_dependency "factory_girl_rails", "~> 4.0.0"
  s.add_development_dependency "database_cleaner", "~> 1.4.1"

  s.add_development_dependency "sqlite3", "~> 1.3.11"
end
