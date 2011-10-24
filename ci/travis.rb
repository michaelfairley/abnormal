if ENV['TESTX']
  system "
    cd test/#{ENV['TESTX']}
    BUNDLE_GEMFILE=Gemfile bundle exec rake test
  "
else
  system 'rake'
end
