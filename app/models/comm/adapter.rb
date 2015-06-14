module Comm
  class Adapter
  
    #FAYE_CLIENT = Faye::Client.new(::FAYE_URL_LOCAL)

    def publish channel, enc_key, msg, user, prio = :normal
      channel = "/#{channel}#{PEER_CHANNEL_PREFIX}#{enc_key}" unless USE_GLOBAL_SUBSCRIBE
      ## Comm::ChannelsController.publish("#{channel}", msg)
      # EM.run {
      #   num_jobs = 1
      #   jobs_done_count = 0

      #   publication = Comm::Adapter::FAYE_CLIENT.publish("#{channel}", msg)
      #   publication.callback { Rails.logger.debug("sent #{channel} to user: user = #{user.id} / #{user.username}"); EM.stop if (jobs_done_count += 1) == num_jobs }
      #   publication.errback {|error| Rails.logger.error("#{channel}to user: user = #{user.id} / #{user.username} - error: #{error.message}"); EM.stop if (jobs_done_count += 1) == num_jobs }
      # }
      #if ![:development].include?(Rails.env.to_sym)# || true
      if prio != :high
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
