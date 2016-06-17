class AROW
  attr_reader :means, :covariances

  def initialize(num_features, r = 0.1)
    @num_features = num_features
    @r = r

    @means = Hash.new{ 0.0 }
    @covariances = Hash.new{ 1.0 }

    File.open("means.tsv") do |f|
      f.each_line do |l|
        term, pos, v = l.split("\t")
        key = [term, pos]
        @means[key] = v.to_f
      end
    end

    File.open("covariances.tsv") do |f|
      f.each_line do |l|
        term, pos, v = l.split("\t")
        key = [term, pos]
        @covariances[key] = v.to_f
      end
    end
  end

  def margins(features)
    features.map{ |key, value| [key, @means[key] * value] }.to_h
  end

  def margin(features)
    result = 0.0

    features.each do |key, value|
      result += @means[key] * value
    end

    return result
  end

  def predict(features)
    puts "score: #{margin(features)}"
    return margin(features) > 0
  end

  def update(features, label)
    margin = margin(features)
    label_value = label

    return false if label_value * margin >= 1

    confidence = 0.0
    features.each do |key, value|
      confidence += @covariances[key] * value * value
    end

    beta = 1.0 / (confidence + @r)
    alpha = label_value * (1.0 - label_value * margin) * beta

    features.each do |key, value|
      v = @covariances[key] * value
      @means[key] += alpha * v
      @covariances[key] -= beta * v * v
    end

    return true
  end
end
