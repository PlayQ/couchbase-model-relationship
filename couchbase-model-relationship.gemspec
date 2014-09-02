# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'couchbase/model/relationship/version'

Gem::Specification.new do |spec|
  spec.name          = "couchbase-model-relationship"
  spec.version       = Couchbase::Model::Relationship::VERSION
  spec.authors       = ["Jon Moses"]
  spec.email         = ["jon@burningbush.us"]
  spec.description   = %q{Closely bound relationships for Couchbase::Model}
  spec.summary       = %q{Supports relationships that are fetched and saved with a root model}
  spec.homepage      = "https://github.com/jmoses/couchbase-model-relationship"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activemodel', '~> 3'
  spec.add_dependency 'activesupport', '~> 3'
  spec.add_dependency 'couchbase', '~> 1'
  spec.add_dependency 'couchbase-model', '0.5.3'
  spec.add_dependency 'json', '~> 1.8.0'
  # FIXME Remove when couchbase is > 1.3.1
  spec.add_dependency 'multi_json', '1.7.5'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'mocha'
end
