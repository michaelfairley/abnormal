require 'abnormal/version'

class Abnormal
  def self.db; @@db; end
  def self.db=(db)
    @@db = db
  end

  def self.ab_test(identity, test_name, alternatives, conversions)
    conversions = [conversions]  unless conversions.is_a? Array

    db['tests'].update(
      {:name => test_name},
      {
        :$set => {
          :alternatives => alternatives,
          :hash => Digest::MD5.hexdigest(test_name),
        },
        :$addToSet => {
          :conversions => {:$each => conversions}
        }
      },
      :upsert => true
    )

    chose_alternative(identity, test_name, alternatives)
  end

  def self.get_test(test_hash)
    db['tests'].find_one(:hash => test_hash)
  end

  def self.tests
    db['tests'].find.to_a
  end

  def self.chose_alternative(identity, test_name, alternatives)
    index = Digest::MD5.hexdigest(test_name + identity).to_i(16) % alternatives.size
    alternatives[index]
  end
end
