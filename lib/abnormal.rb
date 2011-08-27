require 'abnormal/version'

class Abnormal
  def self.db; @@db; end
  def self.db=(db)
    @@db = db
  end

  def self.ab_test(identity, test_name, alternatives, conversions)
    db['tests'].update(
      {:name => test_name},
      {:$set => {:alternatives => alternatives, :id => Digest::MD5.hexdigest(test_name)}},
      :upsert => true
    )

    chose_alternative(identity, test_name, alternatives)
  end

  def self.get_test(test_id)
    db['tests'].find_one(:id => test_id)
  end

  def self.tests
    db['tests'].find.to_a
  end

  def self.chose_alternative(identity, test_name, alternatives)
    index = Digest::MD5.hexdigest(test_name + identity).to_i(16) % alternatives.size
    alternatives[index]
  end
end
