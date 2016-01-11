# -*- encoding: utf-8 -*-
require File.expand_path('../lib/hood/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alex Huang"]
  gem.email         = ["Alex.Huang@laxino.com"]
  gem.description   = %q{library for internal wallet service project}
  gem.summary       = %q{lib for iwms}
  gem.homepage      = "http://homepage@hood.lib"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "hood"
  gem.require_paths = ["lib"]
  gem.version       = Hood::VERSION
end
