# @see Comm.Manager
class CommAdapterMock

  def send channel, enc_key, msg
binding.pry
    #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer.comm_port.channel_enc_key}", msg)
  end

end
