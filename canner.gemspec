# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'canner/version'

Gem::Specification.new do |gem|
  gem.name          = "canner"
  gem.version       = Canner::VERSION
  gem.authors       = ["Joe Acklin"]
  gem.email         = ["joe@acklin.me"]
  gem.summary       = %q{Rails Auth}
  gem.description   = %q{No magic authorization for Rails}
  gem.homepage      = "https://github.com/jacklin10/canner"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activesupport"
  gem.add_development_dependency "activemodel"
  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rspec", "~> 2.1"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "yard"
end
