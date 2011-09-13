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

    alternative = choose_alternative(identity, test_name, alternatives)

    conversions.each do |conversion|
      db['participations'].update(
        {
          :participant => identity,
          :test_id => test_id,
          :conversion => conversion
        },
        {
          :$inc => {
            :conversions => 0,
            :participations => 1
	  },
          :$set => {:alternative => alternative.inspect}
        },
        :upsert => true
      )
    end

    alternative
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

  def self.data_for_report
    counts = db['participations'].group(
      :key => [:test_id, :conversion, :alternative],
      :initial => {
        :part => 0,
        :part_uniq => 0,
        :conv => 0,
        :conv_uniq => 0
      },
      :reduce => "function(obj, prev) {
        prev.part += obj.participations;
        if (obj.participations > 0){
          prev.part_uniq++;
        }
        prev.conv += obj.conversions;
        if (obj.conversions > 0){
          prev.conv_uniq++;
        }
      }"
    )

    counts.group_by { |count| count['test_id'] }.map do |test_id, counts|
      {
        :name => get_test(test_id)['name'],
        :conversions => counts.group_by { |count| count['conversion'] }.map do |conversion, counts|
          {
            :name => conversion,
            :part => counts.inject(0){ |sum,count| sum += count['part'] }.to_i,
            :part_uniq => counts.inject(0){ |sum,count| sum += count['part_uniq'] }.to_i,
            :conv => counts.inject(0){ |sum,count| sum += count['conv'] }.to_i,
            :conv_uniq => counts.inject(0){ |sum,count| sum += count['conv_uniq'] }.to_i,
            :alternatives => counts.map do |count|
              {
                :value => count['alternative'],
                :part => count['part'].to_i,
                :part_uniq => count['part_uniq'].to_i,
                :conv => count['conv'].to_i,
                :conv_uniq => count['conv_uniq'].to_i
              }
            end
          }
        end
      }
    end
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
