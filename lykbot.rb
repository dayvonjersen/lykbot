require 'cinch'
require 'rubygems'
require 'simple-rss'
require 'open-uri'
require 'json'
require 'time-lord'
require 'yaml'

#configure as you want
bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.rizon.net"
    c.channels = ["#channel1", "#channel2"]
    c.nick = "lykbot"
    c.user = "lykbot"
    c.realname = "lykbot"
  end

version = "1.0.0"

#set which channels get rss udates
$rss_chans = ["#peensquad",
              "#xyz",
              "#moogimob"]

#set a nick as an admin
$admin = "lykranian"

  on :message, /^[.!:,]bots/ do |m|
    m.reply "Reporting in! .help"
  end
  on :ctcp, "VERSION" do |m|
    m.ctcp_reply "bot using cinch"
  end
  on :message, /^[.,!^$@]help/ do |m|
    User(m.user.nick).send "lykranian's crappy bot. on github @lykranian/lykbot"
  end

  #.join #chan
  on :message, /^\.join (.+)/ do |m, channel|
    if m.user.nick == admin
      Channel(channel).join
    end
  end
  #.part #chan
  on :message, /^\.part (.+)/ do |m, channel|
    if "#{m.user.nick}" == "lykranian"
      Channel(channel).part
      User("lykranian").send "part from #{channel} successful"
    end
  end

#example of rss parsing
  on :message, ".irssi" do |m|
    rss = SimpleRSS.parse open('https://github.com/irssi/irssi/releases.atom')
    m.reply "latest release - #{rss.items.first.title}"
  end


  #RSS auto updating

  $rss_state = "on"
  on :message, ".rss start" do |m|
    if m.user.nick == admin
      #loads feed links from a .yml file
      $feed_link = YAML.load File.open('feed_link.yml', 'r')
      length = $feed_link.length - 1
      $old = Array.new($feed_link.length, "empty")
      #gets the current most recent articles for each feed link
      for i in 0..length
        $old[i] = get_first_title($feed_link[i])
        sleep(1)
      end
      while $rss_state == "on"
        for i in 0..length
          #to do: make it retry a limited number of times,
          #to prevent infinite loop if feed server is down
          begin
            #gets new feed for each link
            feed = SimpleRSS.parse(open($feed_link[i]))
          rescue Exception
            retry
          end
          sleep(1)
          #compares the stored value with the new feed
          if $old[i] != feed.items.first.title
            for channel in $rss_chans
              #if it differs it sends a channel msg
              #you can change the message text here
              Channel(channel).send "new episode! #{feed.items.first.title}"
              sleep(1)
            end
            #sets the latest feed title as the new old one, to compare against later
            $old[i] = feed.items.first.title
          end
          sleep(1)
        end
        #choose how often it checks for feed updates
        sleep(300)
      end
    end
  end

  #might refresh the rss feed list without having to restart the bot
  #need to add a check to make sure it doesn't do anything while updates are being checked for above
  on :message, ".rss23load" do |m|
    $feed_link = YAML.load File.open('feed_link.yml', 'r')
    length = $feed_link.length - 1
    $old = Array.new($feed_link.length, "empty")
    for i in 0..length
      $old[i] = get_first_title($feed_link[i])
      sleep(1)
    end
  end

  #sends queries to nyaa
  on :message, ".rss23load" do |m|
    $feed_link = YAML.load File.open('feed_link.yml', 'r')
    length = $feed_link.length - 1
    $old = Array.new($feed_link.length, "empty")
    for i in 0..length
      $old[i] = get_first_title($feed_link[i])
      sleep(1)
    end
  end

  #you have mail
  #to do: make un-shitty
    #^ don't complain please be nice

  #loads previously saved mail infos
  $sender = YAML.load File.open('sender.yml', 'r')
  $recipient = YAML.load File.open('recipient.yml', 'r')
  $message = YAML.load File.open('message.yml', 'r')
  $time_send = YAML.load File.open('time_send.yml', 'r')
  #mail send count
  $msc = $sender.length

  on :message, ".mail" do |m|
    m.reply ".mail nick message | .mailbox"
  end

  on :message, /^\.mail (.+?) (.+)/ do |m, recipient_get, message_get|
    recipient_down = recipient_get.downcase
    $sender[$msc] = m.user.nick
    $recipient[$msc] = recipient_down
    $message[$msc] = message_get
    time_temp = Time.now.to_i
    $time_send[$msc] = time_temp
    User(m.user.nick).send "your mail is on its way to #{recipient_get}'s mailbox"
    $msc = $msc + 1
    #writes mail info so there's an up-to-date version if the bot shuts downn
    #prevents messages from getting lost
    File.open('sender.yml', 'w') do |f|
      f.write $sender.to_yaml
    end
    File.open('recipient.yml', 'w') do |f|
      f.write $recipient.to_yaml
    end
    File.open('message.yml', 'w') do |f|
      f.write $message.to_yaml
    end
    File.open('time_send.yml', 'w') do |f|
      f.write $time_send.to_yaml
    end
  end

  #message send count
  on :message, ".msc" do |m|
    m.reply "#{$msc} mails sent"
  end

  #tells people if they have mail if they join a channel with the bot
  on :join, do |m|
    length = $recipient.length - 1
    count = 0
    for i in 0..length
      rec_nick = $recipient [i]
      if m.user.nick.downcase == rec_nick.downcase
        count = count + 1
      end
    end
    if count != 0
        User(m.user.nick).send "you have mail (#{count} unread)! simply respond to this message to check."
    end
  end

#checks and sends mail for each message that the bot recieves
  on :message, do |m|
    length = $recipient.length - 1
    for i in 0..length
      rec_nick = $recipient [i]
      if m.user.nick.downcase == rec_nick.downcase
        time_diff = Time.now.to_i - $time_send[i]
                     #vvvvvvvv this is where time_lord comes in
        time_check = time_diff.seconds.ago.to_words
        User(m.user.nick).send "| from %s, #{time_check}: #{$message[i]}" % [Format(:yellow, "#{$sender[i]}")]
        #removes the recipient, so that the mail will never be sent again
        $recipient[i] = "~recieved~"
        #removes the message contents, so that pivacy is respected
        $messagee[i] = "~revieved~"
        #should probably write a function or something huh
        File.open('sender.yml', 'w') do |f|
          f.write $sender.to_yaml
        end
        File.open('recipient.yml', 'w') do |f|
          f.write $recipient.to_yaml
        end
        File.open('message.yml', 'w') do |f|
          f.write $message.to_yaml
        end
        File.open('time_send.yml', 'w') do |f|
          f.write $time_send.to_yaml
        end
        sleep(1)
      end
    end
  end
  
  #slightly changed google search from cpt_yossarian's yossarian-bot
  #https://github.com/woodruffw/yossarian-bot
  #'Copyright (c) 2015 William Woodruff <william @ tuffbizz.com>' licenses are scary
  helpers do
    def google(m, search)
      url = URI.encode("https://ajax.googleapis.com/ajax/services/search/web?v=1.0&rsz=large&safe=active&q=#{search}&max-results=1&v=2&prettyprint=false&alt=json")
      hash = JSON.parse(open(url).read)
      unless hash['responseData']['results'].empty?
        site = hash['responseData']['results'][0]['url']
        content = hash['responseData']['results'][0]['content'].gsub(/([\t\r\n])|(<(\/)?b>)/, '')
        content.gsub!(/(&amp;)|(&quot;)|(&lt;)|(&gt;)|(&#39;)/, '&amp;' => '&', '&quot;' => '"', '&lt;' => '<', '&gt;' => '>', '&#39;' => '\'')
        site = URI.unescape(site)
        m.reply "#{m.user.nick}: #{content} | #{site}"
      else
        m.reply "i'm afraid i can't do that, #{m.user.nick}."
      end
    end
  end
  on :message, /^.g (.+)/ do |m, query|
    google(m, query)
  end

  on :message, ".hbomb" do |m|
    m.reply ".idle"
  end

end

bot.start
