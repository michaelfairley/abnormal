require 'rubygems'
require 'bundler/setup'
require 'simplecov'
SimpleCov.start

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
    end

    describe "multiple calls for the same test" do
      it "doesn't add a duplicate test" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id2', 'test', [1, 2], 'conversion')
        Abnormal.should have(1).tests
      end
    end

    describe "multiple calls for multiple tests" do
      it "should create multiple tests" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id', 'test2', [1, 2], 'conversion')
        Abnormal.should have(2).tests
      end
    end

    describe "a call with one conversion" do
      it "sets that conversion on the test" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.get_test(Digest::MD5.hexdigest('test'))['conversions'].to_set.should == %w[conversion].to_set
      end
    end

    describe "multiple calls with the same conversion" do
      it "doesn't add a duplicate conversions" do
        Abnormal.ab_test('id1', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id2', 'test', [1, 2], 'conversion')
        Abnormal.get_test(Digest::MD5.hexdigest('test'))['conversions'].should have(1).items
      end
    end

    describe "a call with multiple conversions" do
      it "sets all of the conversions" do
        Abnormal.ab_test('id', 'test', [1, 2], %w[conversion1 conversion2])
        Abnormal.get_test(Digest::MD5.hexdigest('test'))['conversions'].to_set.should == %w[conversion1 conversion2].to_set
      end
    end

    describe "multiple calls with different conversions" do
      it "sets all of the conversions" do
        Abnormal.ab_test('id1', 'test', [1, 2], 'conversion1')
        Abnormal.ab_test('id2', 'test', [1, 2], 'conversion2')
        Abnormal.get_test(Digest::MD5.hexdigest('test'))['conversions'].to_set.should == %w[conversion1 conversion2].to_set
      end
    end

    it "returns the correct alternative" do
      Abnormal.stub(:chose_alternative){ 3 }
      Abnormal.ab_test('id', 'test', [1, 2], 'conversion').should == 3
    end
  end

  # I don't like any of these... is there a better way to do this?
  describe "choose_alternative" do
    it "returns the same result for the same user and test" do
      alt1 = Abnormal.chose_alternative('id', 'test', [1, 2])
      alt2 = Abnormal.chose_alternative('id', 'test', [1, 2])
      alt1.should == alt2
    end

    it "returns different results for different users" do
      alt1 = Abnormal.chose_alternative('id1', 'test', [1, 2])
      alt2 = Abnormal.chose_alternative('id2', 'test', [1, 2])
      alt1.should_not == alt2
    end

    it "returns different results for different tests" do
      alt1 = Abnormal.chose_alternative('id', 'test_1', [1, 2])
      alt2 = Abnormal.chose_alternative('id', 'test2', [1, 2])
      alt1.should_not == alt2
    end

    it "returns all possible alternatives" do
      alternatives = [1, 2]
      actual_alternatives = (1..10).map{|i| Abnormal.chose_alternative("id#{i}", 'test', alternatives) }

      actual_alternatives.to_set.should == alternatives.to_set
    end
  end
end
