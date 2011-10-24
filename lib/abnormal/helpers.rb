module Abnormal::Helpers
  def ab_test(test, alternatives, conversions)
    Abnormal.ab_test(Abnormal.identity, test, alternatives, conversions)
  end

  def convert!(*args)
    args.unshift Abnormal.identity
    Abnormal.convert!(*args)
  end
end
