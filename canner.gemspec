# -*- encoding: utf-8 -*-
lib = File.expand_path('lib', __dir__)
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

  gem.metadata = {
    "homepage_uri"      => "https://github.com/jacklin10/canner",
    "source_code_uri"   => "https://github.com/jacklin10/canner",
    "bug_tracker_uri"   => "https://github.com/jacklin10/canner/issues",
    "changelog_uri"     => "https://github.com/jacklin10/canner/blob/master/CHANGELOG.md"
  }

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.5.0"

  gem.add_dependency "activesupport", ">= 4.0"
  gem.add_development_dependency "activemodel"
  gem.add_development_dependency "bundler", ">= 1.3"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "yard"
end
