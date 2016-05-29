# coding:utf-8

require './bot.rb'

bot = Bot.new

begin
  bot.stream.user do |status|
    #p status
    case status
    when Twitter::Tweet
      puts status.text
      user = status.user.screen_name
      if !status.text.index("RT")
        if !(/^@\w*/.match(status.text))
          if bot.tsurai?(status.text)
            text = ["人生は楽しい", bot.retrieve].join(" ")
            bot.tweet(user: user, text: text, in_reply_to_status: status)
            puts text
          end
        end
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
