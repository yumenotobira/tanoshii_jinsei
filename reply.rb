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
        tweet.destroy
      elsif status.text.index(":学習:")
        _, _, label, text = status.text.split(":")
        label = label.to_i

        if label != 1 && label != -1 || text.nil?
          tweet = "フォーマットエラーのため学習できませんでした"
          bot.tweet(user: status.user.screen_name, text: tweet, in_reply_to_status: status)
          next
        end

        bot.learn(text, label)
        bot.output
        tweet = label == 1 ? "鬱として学習" : "鬱じゃないとして学習"
        bot.tweet(user: status.user.screen_name, text: tweet, in_reply_to_status: status)
      elsif bot.tsurai?(status.text)
        text = ["人生は楽しい", bot.retrieve, status.url].join(" ")
        media_id = bot.image(status.text)
        tweet = bot.tweet(text: text, media_ids: media_id)
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
