# coding:utf-8

require 'twitter'
require 'dotenv'
require 'flickraw'
require 'set'

Dotenv.load

class Bot
  attr_accessor :rest, :stream
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

    @dict = Set.new
    File.open(File.expand_path("../dictionary.txt", __FILE__)) do |f|
      f.each_line do |l|
        @dict.add(l.chomp)
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

  def tsurai?(text)
    @dict.any?{ |d| text =~ /#{d}/ }
  end

  def retrieve
    word = tags.sample
    url = flickr.photos.search(tags: word, sort: "relevance").map{ |i| FlickRaw.url(i) }.sample
    return url
  end
end
