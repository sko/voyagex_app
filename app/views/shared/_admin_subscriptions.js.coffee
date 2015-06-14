channelPath = '/system'
unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
  channelPath += VoyageX.PEER_CHANNEL_PREFIX+'<%=sys_channel_enc_key%>'
window.adminSubscribeTo.push channelPath
