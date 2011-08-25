require 'rubygems'
require 'bundler/setup'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'abnormal'

Bundler.require(:development)

describe Abnormal do
  before(:all) do
    Abnormal.db = Mongo::Connection.new['abnormal_test']
  end

  before(:each) do
    Abnormal.db['tests'].drop
  end

  describe 'ab_test' do
    describe 'the first call for a new test' do
      it "adds that test to the test table" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
	Abnormal.get_test(Digest::MD5.hexdigest('test'))['name'].should == 'test'
      end

      it "doesn't add a duplicate test when the same test is called" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id2', 'test', [1, 2], 'conversion')
        Abnormal.should have(1).tests
      end
    end
  end
end