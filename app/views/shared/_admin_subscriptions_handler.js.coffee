adminSubscriptionHandler = (message) ->
  switch message.type
    when 'debug'
      msg = {peer: {id: message.userId, username: message.userName, foto: message.userFoto}, text: message.type+': '+message.msg}
      VoyageX.View.addChatMessage msg, false
    when 'error'
      msg = {peer: {id: message.userId, username: message.userName, foto: message.userFoto}, text: message.type+': '+message.msg}
      VoyageX.View.addChatMessage msg, false

# subscribe to all channels stored in subscribeTo-buffer
while (channelPath = adminSubscribeTo.pop())
  i = channelPath.indexOf(VoyageX.PEER_CHANNEL_PREFIX)
  channel = (if i == -1 then channelPath else channelPath.substr(0, i)).substr(1)
  Comm.Comm.subscribeTo channelPath, adminSubscriptionHandler, false
