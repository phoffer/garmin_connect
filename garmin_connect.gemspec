# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'garmin_connect/version'

Gem::Specification.new do |gem|
  gem.name          = "garmin_connect"
  gem.version       = GarminConnect::VERSION
  gem.authors       = ["Paul Hoffer"]
  gem.email         = ["paulrhoffer@gmail.com"]
  gem.description   = %q{Work with Garmin Connect data easily}
  gem.summary       = %q{Work with Garmin Connect data easily}
  gem.homepage      = "http://github.com/phoffer/garmin_connect"
  gem.license       = 'MIT'
  gem.files         = Dir.glob("lib/**/*") + %w(LICENSE.txt README.md Rakefile)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  # gem.add_dependency "activesupport", [">= 4.0.0"]
  gem.add_runtime_dependency 'activesupport', '~> 4.0', '>= 4.0.0'
end
