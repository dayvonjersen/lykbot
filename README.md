# lykbot
a little irc bot that does some things.

#### mail
you can send messages to users if they're offline with `.mail`.

`.mail lykranian message goes here`

they will be notified on next activity (message or join)

#### rss
auto-rss updating. `.rss start` needs to be sent to the bot when it starts, but from then on it should update a list of channels with the most recent feed item from a list of links.

#### other
`.g` to search google, `.join #chan` and `.part #chan`

that's pretty much it.

#### required things
requires some gems

`gem install cinch simple-rss json time-lord`

if you get ruby version errors, good luck

you also need some files in the directory that you run the ruby command from.

it'd be best to keep them in the bot directory, and always launch the bot from there. make an alias to do it for you.

`alias lykbot='cd ~/lykbot && screen -d ruby lykbot.rb && cd $OLDPWD'` should work probably

files needed:

```
feed_link.yml
sennder.yml
recipient.yml
message.yml
time_send.yml
```

#### to do:
plenty of things.
