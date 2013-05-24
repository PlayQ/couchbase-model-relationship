lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'rspec/core'

require 'couchbase/model/relationship'

module RspecHelpers
  def stub_instance(klass, stubs = {})
    stub = stub(klass.name)
    stub.responds_like_instance_of(klass)

    stub.stubs(stubs) if stubs && ! stubs.empty?

    stub
  end

  def stub_klass(klass)
    stub = stub(klass.name)
    stub.responds_like(klass)

    stub
  end
end


RSpec.configure do |config|
  config.mock_framework = :mocha
  config.include RspecHelpers
end

Mocha::Configuration.prevent :stubbing_non_existent_method
Mocha::Configuration.prevent :stubbing_method_on_nil

