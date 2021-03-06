# frozen_string_literal: true

def formatted_name(user)
  "#{user.name}##{user.discriminator}"
end

def find_prefix(message)
  ServerConfig[message.server.id].server_prefix || QBot.config.global.prefix || '.'
end

def cmd_prefix(message)
  pfx = find_prefix(message)

  if message.text.start_with?(pfx + ' ')
    message.text[(pfx.length + 1)..-1]
  elsif message.text.start_with?(pfx)
    message.text[pfx.length..-1]
  end
end

def log_embed(event, chan_id, user, extra)
  event.bot.channel(chan_id).send_embed do |m|
    m.author = { name: formatted_name(user), icon_url: user.avatar_url }
    m.title = 'Command execution'
    m.fields = [
      { name: 'Command', value: event.message.to_s, inline: true },
      { name: 'User ID', value: user.id, inline: true }
    ]
    extra && m.fields << [{ name: 'Information', value: extra }]
    m.timestamp = Time.now
  end
end

def log(event, extra = nil)
  user = event.author

  chan_id = ServerConfig[event.server.id].log_channel_id

  QBot.log.info("command execution by #{formatted_name(user)}: " \
                "#{event.message}#{extra && "; #{extra}"}")

  log_embed(event, chan_id, user, extra) if chan_id
end

# Listen for a user response
def user_response(event)
  response = event.bot.add_await!(Discordrb::Events::MentionEvent, in: event.channel, from: event.author)
  response.message.text.split[1].to_i
end

def unescape(str)
  "\"#{str}\"".undump
end
