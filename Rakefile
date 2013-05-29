require "bundler/gem_tasks"

require 'rake/testtask'
require 'rake/clean'

rule 'test/CouchbaseMock.jar' do |task|
  jar_path = "0.5-SNAPSHOT/CouchbaseMock-0.5-20120726.220757-19.jar"
  sh %{wget -q -O spec/CouchbaseMock.jar http://files.couchbase.com/maven2/org/couchbase/mock/CouchbaseMock/#{jar_path}}
end

CLOBBER << 'spec/CouchbaseMock.jar'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

#Rake::Task['spec'].prerequisites.unshift('test/CouchbaseMock.jar')
