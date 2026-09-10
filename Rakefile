require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
Rake::TestTask.new(:test) { |t| t.pattern = "test/v1/**/*_test.rb" }
task default: :test
