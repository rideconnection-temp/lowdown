require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rubygems'

desc 'Default: run unit tests.'
task :default=>:test

desc 'Test the point_in_time plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.libs << 'test/models'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "novalis-point_in_time"
    gemspec.summary = "Gemified version of the point_in_time plugin"
    gemspec.description = "point_in_time is a ActveRecord versioning gem that allows point-in-time queries."
    gemspec.email = ""
    gemspec.homepage = "https://github.com/chrispatterson/lowdown"
    gemspec.authors = ["David Turner"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
