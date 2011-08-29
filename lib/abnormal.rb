require 'abnormal/version'

class Abnormal
  def self.db; @@db; end
  def self.db=(db)
    @@db = db
  end

  def self.ab_test(identity, test_name, alternatives, conversions)
    conversions = [conversions]  unless conversions.is_a? Array

    test_id = Digest::MD5.hexdigest(test_name)
    db['tests'].update(
      {:name => test_name, :_id => test_id},
      {
        :$set => {
          :alternatives => alternatives,
        },
        :$addToSet => {
          :conversions => {:$each => conversions}
        }
      },
      :upsert => true
    )

    conversions.each do |conversion|
      db['participations'].update(
        {
          :participant => identity,
          :test_id => test_id,
          :conversion => conversion
        },
        {
          :$set => {:conversions => 0}
        },
        :upsert => true
      )
    end

    choose_alternative(identity, test_name, alternatives)
  end

  def self.convert!(identity, conversion, score = 1)
    db['participations'].update(
      {
        :participant => identity,
        :conversion => conversion
      },
      {
        :$inc => {:conversions => score}
      },
      :multi => true
    )
  end

  def self.get_test(test_id)
    db['tests'].find_one(:_id => test_id)
  end

  def self.tests
    db['tests'].find.to_a
  end

  def self.get_participation(id, test_name, conversion)
    db['participations'].find_one(
      :participant => id,
      :test_id => Digest::MD5.hexdigest(test_name),
      :conversion => conversion
    )
  end

  def self.participations
    db['participations'].find.to_a
  end

  def self.choose_alternative(identity, test_name, alternatives)
    alternatives_array = normalize_alternatives(alternatives)
    index = Digest::MD5.hexdigest(test_name + identity).to_i(16) % alternatives_array.size
    alternatives_array[index]
  end

  def self.normalize_alternatives(alternatives)
    case alternatives
    when Array
      alternatives
    when Hash
      alternatives_array = []
      idx = 0
      alternatives.each{|k,v| alternatives_array.fill(k, idx, v); idx += v}
      alternatives_array
    when Range
      alternatives.to_a
    end
  end
end
