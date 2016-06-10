# coding:utf-8

require './bot.rb'
require './tweet.rb'

bot = Bot.new

begin
  bot.stream.user do |status|
    p status
    case status
    when Twitter::Tweet
      puts [status.id, status.in_reply_to_user_id, status.text].join(":")
      user = status.user.screen_name

      next if status.text.index("RT")
      next if status.source =~ /tanoshii_jinsei/

      if status.text.match(/^@\w*/)
        next unless status.in_reply_to_user_id == 523377488
        next unless status.text.match(/((ちが)|違)う/)

        tweet = Tweet.where(jinsei_id: status.in_reply_to_status_id).first
        next if tweet.nil?
        tweet.label = -1
        bot.learn(tweet.tweet, tweet.label)
        bot.output
        bot.tweet(text: "鬱じゃないとして学習 #{tweet.url}")
        tweet.destroy
      elsif bot.tsurai?(status.text) || rand < 0.2
        text = ["人生は楽しい", bot.retrieve, status.url].join(" ")
        tweet = bot.tweet(text: text)
        id = tweet.id
        puts text
        Tweet.create(jinsei_id: id, tweet: status.text, url: status.url, label: 0)
      end
    when Twitter::Streaming::Event
      if status.name == :favorite
        id = status.target_object.id
        tweet = Tweet.where(jinsei_id: id).first
        next if tweet.nil?
        tweet.label = 1
        bot.learn(tweet.tweet, tweet.label)
        bot.output
        bot.tweet(text: "鬱として学習 #{tweet.url}")
        tweet.destroy
      end
    end
  end
rescue => em
  puts Time.now
  p em
  sleep 2
  retry
rescue Interrupt
  exit 1
end
