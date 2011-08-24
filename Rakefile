require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/abnormal/version', __FILE__)

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the A/Bnormal plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

desc 'Builds the gem'
task :build do
  sh "gem build abnormal.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install abnormal-#{Abnormal::VERSION}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Abnormal::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{Abnormal::VERSION}"
  sh "gem push abnormal-#{Abnormal::VERSION}.gem"
end
