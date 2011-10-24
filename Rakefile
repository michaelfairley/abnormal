require 'rake'
require 'rspec/core/rake_task'
require File.expand_path('../lib/abnormal/version', __FILE__)

task :default => :spec

RSpec::Core::RakeTask.new(:spec)

task :test_all => :spec do
  %w[rails3].each do |dir|
    sh <<-CMD
      cd test/#{dir}
      BUNDLE_GEMFILE=Gemfile bundle exec rake test
    CMD
  end
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
