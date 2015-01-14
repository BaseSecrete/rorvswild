# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rorvswild/version'

Gem::Specification.new do |spec|
  spec.name          = "rorvswild"
  spec.version       = RorVsWild::VERSION
  spec.authors       = ["Alexis Bernard"]
  spec.email         = ["alexis@bernard.io"]
  spec.summary       = "Simple Ruby on Rails application monitoring for hardcore developers with no time to waste."
  spec.description   = "Simple Ruby on Rails application monitoring for hardcore developers with no time to waste."
  spec.homepage      = "http://www.rorvswild.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
end
