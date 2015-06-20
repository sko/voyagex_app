module Comm
  class Adapter

    def publish channel, enc_key, msg, user, prio = :normal
      channel = "/#{channel}#{PEER_CHANNEL_PREFIX}#{enc_key}" unless USE_GLOBAL_SUBSCRIBE
      if (prio != :high) && (![:development].include?(Rails.env.to_sym))
        Resque.enqueue Publisher, { action: 'publish',
                                    channel: channel,
                                    msg: msg,
                                    user_id: user.id } 
      else
        msgs_data = [
                      { channel: channel,
                        msg: msg,
                        user_id: user.id }
                    ]
        Publisher.new.publish msgs_data, false
      end
    end

  end
end
