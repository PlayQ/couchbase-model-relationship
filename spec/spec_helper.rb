lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'
require 'rspec/core'

require 'couchbase/model/relationship'

RSpec.configure do |config|
  config.mock_framework = :mocha
end
