#!/usr/bin/env ruby

if ENV['TESTX']
  system <<-CMD
    cd test/#{ENV['TESTX']}
    BUNDLE_GEMFILE=Gemfile bundle exec rake test
  CMD
else
  system 'bundle exec rake'
end
