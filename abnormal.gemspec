# encoding: UTF-8
require File.expand_path('../lib/abnormal/version', __FILE__)

Gem::Specification.new do |s|
  s.name               = 'abnormal'
  s.homepage           = 'http://github.com/michaelfairley/abnormal'
  s.summary            = 'Ruby A/B testing'
  s.require_path       = 'lib'
  s.authors            = ['Michael Fairley']
  s.email              = ['michaelfairley@gmail.com']
  s.version            = Abnormal::VERSION
  s.files              = Dir.glob("{lib,test,spec}/**/*") + %w[MIT-LICENSE README.md]
  s.license            = 'MIT'
  s.test_files         = Dir.glob('test/*.rb') + Dir.glob('spec/*.rb')

  s.add_dependency 'mongo'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end