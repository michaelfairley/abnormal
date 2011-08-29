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
    Abnormal.db['participations'].drop
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
        Abnormal.ab_test('id1', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id2', 'test', [1, 2], 'conversion')
        Abnormal.should have(1).tests
      end
    end

    describe "multiple calls for multiple tests" do
      it "creates multiple tests" do
        Abnormal.ab_test('id', 'test1', [1, 2], 'conversion')
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

    describe "the first call by an identity that has not participated in the test with the conversion" do
      it "records in the participation" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.get_participation('id', 'test', 'conversion').should be
      end

      it "has 0 conversions" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.get_participation('id', 'test', 'conversion')['conversions'].should == 0
      end
    end

    describe "subsequent calls by an identity that has participated in the test with the conversion" do
      it "records in the participation" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion')
        Abnormal.should have(1).participations
      end
    end

    describe "a call with multiple conversions" do
      it "makes multiple participations" do
        Abnormal.ab_test('id1', 'test', [1, 2], %w[conversion1 conversion2])
        Abnormal.should have(2).participations
      end
    end

    describe "different calls by different identities" do
      it "makes different participations" do
        Abnormal.ab_test('id1', 'test', [1, 2], 'conversion')
        Abnormal.ab_test('id2', 'test', [1, 2], 'conversion')
        Abnormal.should have(2).participations
      end
    end

    describe "different calls for different tests" do
      it "makes different participations" do
        Abnormal.ab_test('id', 'test1', [1, 2], 'conversion')
        Abnormal.ab_test('id', 'test2', [1, 2], 'conversion')
        Abnormal.should have(2).participations
      end
    end

    describe "different calls with different conversions" do
      it "makes different participations" do
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion1')
        Abnormal.ab_test('id', 'test', [1, 2], 'conversion2')
        Abnormal.should have(2).participations
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

    it "uses normalize_alternatives" do
      Abnormal.stub(:normalize_alternatives){ [3] }
      Abnormal.chose_alternative('id', 'test1', [1, 2]).should == 3
    end
  end

  describe "convert!" do
    describe "with an identity/conversion pair that does not exist" do
      it "does nothing" do
        Abnormal.convert!('id', 'conversion')
        Abnormal.should have(0).participations
      end

      it "does not apply to future participations" do
        identity = 'id'
        test_name = 'test'
        conversion = 'conversion'

        Abnormal.convert!(identity, conversion)
        Abnormal.ab_test(identity, test_name, [1, 2], conversion)
        Abnormal.get_participation(identity, test_name, conversion)['conversions'].should == 0
      end
    end

    describe "with an identity/conversion pair that does exist" do
      it "records the conversions" do
        identity = 'id'
        test_name = 'test'
        conversion = 'conversion'

        Abnormal.ab_test(identity, test_name, [1, 2], conversion)
        Abnormal.convert!(identity, conversion)
        Abnormal.get_participation(identity, test_name, conversion)['conversions'].should == 1
      end
    end

    describe "an identity participating in multiple tests with the conversions" do
      it "records the conversion for the each test" do
        identity = 'id'
        conversion = 'conversion'

        Abnormal.ab_test(identity, 'test1', [1, 2], conversion)
        Abnormal.ab_test(identity, 'test2', [1, 2], conversion)
        Abnormal.convert!(identity, conversion)
        Abnormal.get_participation(identity, 'test1', conversion)['conversions'].should == 1
        Abnormal.get_participation(identity, 'test2', conversion)['conversions'].should == 1
      end
    end

    describe "an identity participating in multiple tests, not all of which have the conversion" do
      it "only records a conversion for the test listening to that conversion" do
        identity = 'id'

        Abnormal.ab_test(identity, 'test1', [1, 2], 'conversion1')
        Abnormal.ab_test(identity, 'test2', [1, 2], 'conversion2')
        Abnormal.convert!(identity, 'conversion1')
        Abnormal.get_participation(identity, 'test1', 'conversion1')['conversions'].should == 1
        Abnormal.get_participation(identity, 'test2', 'conversion2')['conversions'].should == 0
      end
    end
  end

  describe "normalize_alternatives" do
    describe "given an array" do
      it "returns the array" do
        Abnormal.normalize_alternatives([1, 2, 7]).should == [1, 2, 7]
      end
    end

    describe "given a hash" do
      it "expands the hash into an array" do
        Abnormal.normalize_alternatives({:a => 1, :b => 9}).should == [:a, :b, :b, :b, :b, :b, :b, :b, :b, :b]
      end
    end

    describe "given a range" do
      it "converts the range into a hash" do
        Abnormal.normalize_alternatives(1..10).should == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      end
    end
  end
end
