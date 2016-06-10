# coding:utf-8

require 'twitter'
require 'dotenv'
require 'flickraw'
require 'natto'
require './arow.rb'

Dotenv.load

class Bot
  attr_accessor :rest, :stream, :arow
  def initialize
    @rest = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end

    @stream = Twitter::Streaming::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end

    FlickRaw.api_key = ENV['FLICKR_API_KEY']
    FlickRaw.shared_secret = ENV['FLICKR_SEC_KEY']

    num_features = `wc -l dictionary.tsv`.split.first
    @arow = AROW.new(num_features)
    @natto = Natto::MeCab.new
    @dict = {}
    File.open(File.expand_path("../dictionary.tsv", __FILE__)) do |f|
      f.each_line do |l|
        term, pos, idf = l.split("\t")
        key = [term, pos]
        @dict[key] = idf.to_f
      end
    end

    @tags = Array.new
    File.open(File.expand_path("../tags.txt", __FILE__)) do |f|
      f.each_line do |l|
        @tags << l.chomp
      end
    end
  end

  def tweet(user: nil, text: nil, in_reply_to_status: nil)
    if user
      @rest.update("@#{user} #{text}", in_reply_to_status: in_reply_to_status)
    else
      @rest.update("#{text}")
    end
  end

  def vectorize(text)
    features = {}
    @natto.parse(text) do |n|
      break if n.is_eos?
      key = [n.surface, n.feature.split(',')[0]]
      next unless @dict.has_key?(key)
      features[key] = 0 unless features.has_key?(key)
      features[key] += 1
    end

    # 正規化
    n = 0
    features.each{ |key, value| n += value * value }
    features.keys{ |key| features[key] /= Math.sqrt(n) }
    return features
  end

  def tsurai?(text)
    features = vectorize(text)
    @arow.predict(features)
  end

  def learn(text, label)
    features = vectorize(text)
    @arow.update(features, label)
  end

  def output
    File.open("means.tsv", "w") do |file|
      @arow.means.each do |key, value|
        file.puts [key[0], key[1], value].join("\t")
      end
    end

    File.open("covariances.tsv", "w") do |file|
      @arow.covariances.each do |key, value|
        file.puts [key[0], key[1], value].join("\t")
      end
    end
  end

  def retrieve
    word = @tags.sample
    url = flickr.photos.search(tags: word, sort: "relevance").map{ |i| FlickRaw.url(i) }.sample
    return url
  end
end
