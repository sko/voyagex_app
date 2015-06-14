#require 'faye'
class Publisher
  include PoiHelper
  
  FAYE_CLIENT = Faye::Client.new(::FAYE_URL_LOCAL)

  # queue for resque
  @queue = :publish

  # callback for resque-worker
  def self.perform *args
    args_hash = args.first
    case args_hash['action']
      when 'publish'
        Publisher.publish args_hash['channel'], args_hash['msg'], args_hash['user_id']
    end
  end

  def self.publish channel, msgJSON, user_id
    Publisher.new.publish [{channel: channel, msg: msgJSON, user_id: user_id}]
  end
  
  def publish messages, fork = true
    num_jobs = messages.length
    jobs_done_count = 0
    if fork
      EM.run {
        messages.each do |msg_data|
          publication = Publisher::FAYE_CLIENT.publish("#{msg_data[:channel]}", msg_data[:msg])
          publication.callback { Rails.logger.debug("sender #{msg_data[:user_id]} to #{msg_data[:channel]}"); EM.stop if (jobs_done_count += 1) == num_jobs }
          publication.errback {|error| Rails.logger.error("#{msg_data[:channel]} - error: #{error.message}"); EM.stop if (jobs_done_count += 1) == num_jobs }
        end
      }
    else
      messages.each do |msg_data|
        #Comm::ChannelsController.publish("#{msg_data[:channel]}", msg_data[:msg])
        Publisher::FAYE_CLIENT.publish("#{msg_data[:channel]}", msg_data[:msg])
      end
    end
  end

end
