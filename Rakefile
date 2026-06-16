# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/dummy/**/*")
end

desc "Run lightweight checks that don't require test/dummy (for CI)"
task :ci do
  sh "gem build admin_generator.gemspec --output=/dev/null"

  lib_files = FileList["lib/**/*.rb"]
  lib_files.each { |f| sh "ruby -c #{f}" }

  sh "ruby -Ilib -e 'require \"admin_generator\"'"
end

task default: :test
