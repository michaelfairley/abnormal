if ENV['TESTX']
  system <<-CMD
    cd test/#{ENV['TESTX']}
    BUNDLE_GEMFILE=Gemfile bundle exec rake test
  CMD
else
  system 'rake'
end