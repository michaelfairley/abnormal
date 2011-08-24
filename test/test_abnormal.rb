require 'rubygems'
require 'bundler/setup'
require 'test/unit'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'abnormal'

Bundler.require(:development)

class TestAbnormal < Test::Unit::TestCase
  def setup
  end
end
