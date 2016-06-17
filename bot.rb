# coding:utf-8

require 'twitter'
require 'dotenv'
require 'flickraw'
require 'natto'
require 'gnuplot'
require './arow.rb'

Dotenv.load

class Bot
  attr_accessor :rest, :stream, :arow
  UNK_IDF = 12.5640442484431

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

    # いらない形態素のパターン
    @reject_patterns = [
      /^([a-zA-Z]+)$/, # 半角アルファベットだけで構成
      /^(\s+)$/, # 空白だけで構成
      /^(\d+)$/, # 半角数字だけで構成
      /^([\(\)\[\]\{\}\.\?\+\*\|\\\/:-~=#!"`'<>,%&$^]+)$/, # 半角記号だけで構成
    ]

    @tags = Array.new
    File.open(File.expand_path("../tags.txt", __FILE__)) do |f|
      f.each_line do |l|
        @tags << l.chomp
      end
    end
  end

  def tweet(user: nil, text: nil, in_reply_to_status: nil, media_ids: nil)
    if user
      @rest.update("@#{user} #{text}", in_reply_to_status: in_reply_to_status)
    else
      @rest.update("#{text}", {media_ids: media_ids})
    end
  end

  def vectorize(text)
    features = Hash.new{ 0.0 }
    @natto.parse(text) do |n|
      break if n.is_eos?

      next if @reject_patterns.any?{ |p| n.surface.match(p) }
      next if n.feature.split(',')[0] == "記号"

      key = [n.surface, n.feature.split(',')[0]]

      idf = @dict.has_key?(key) ? @dict[key] : UNK_IDF
      features[key] += idf
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

  def image(text)
    term_scores = @arow.margins(vectorize(text))
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal 'png enhanced font "IPA P ゴシック" fontscale 1.2'
        plot.output "plot.png"
        plot.ylabel "score"
        plot.xlabel "terms"
        plot.grid
        plot.set 'style fill solid border lc rgb "black"'
        plot.set "boxwidth 0.5 relative"

        x, y = [], []
        term_scores.each do |term, value|
          x << term
          y << value
        end
        total = y.reduce(:+)
        y << total
        x << "合計スコア"

        plot.data << Gnuplot::DataSet.new([y,x]) do |ds|
          ds.using = "1:xtic(2)"
          ds.with = "boxes lw 2"
          ds.notitle
        end
      end
    end

    return @rest.upload(File.new("./plot.png"))
  end

  def retrieve
    word = @tags.sample
    url = flickr.photos.search(tags: word, sort: "relevance").map{ |i| FlickRaw.url(i) }.sample
    return url
  end
end
