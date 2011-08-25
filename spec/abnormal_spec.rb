require 'rubygems'
require 'bundler/setup'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'abnormal'

Bundler.require(:development)

describe Abnormal do
  describe 'ab_test' do
    describe 'the first call for a new test' do
      it 'adds that test to the test table' do

      end
    end
  end
end