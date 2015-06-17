#require_dependency "comm/application_controller"

# curl -X POST http://192.168.1.4:3005/comm -H 'Content-Type: application/json' -d '{"channel":"/talk@rxbcin9nc","data":{"type":"chat", "text":"hello world"}}'
include ::GeoUtils
include ::ApplicationHelper
module Comm
  class ChannelsController < FayeRails::Controller

    LOGGER = Logger.new("#{Rails.root}/log/channels.log")

    # if creation of new channels by clients should be supervised/disabled then do:
    # https://github.com/jamesotron/faye-rails#model-observers
    #observe Channel, :after_create do |new_channel|
    #  ChannelsController.publish('/widgets', new_widget.attributes)
    #end

    channel '/system**' do
      monitor :subscribe do
        #Client igt3vtbefo1rfmo5afi7wig5y7x3vx7 subscribed to /system@8jruy0aws.
        LOGGER.debug "+++ #{channel} - subscribe ### Client #{client_id}"
        subscription_enc_key = channel.match(/^\/system#{PEER_CHANNEL_PREFIX}([^\/]+)/)
        if subscription_enc_key.present?
          #
          # when a client subscribes he gets a ready-notification
          #
          begin
            admin_cp = CommPort.joins(:user).where(current_faye_client_id: client_id, users: {email: ::ADMIN_EMAIL_ADDRESS}).first
            # admin user can subscribe to system-channel from other user
            unless admin_cp.present? && admin_cp.sys_channel_enc_key != subscription_enc_key[1]
              comm_port = CommPort.where(sys_channel_enc_key: subscription_enc_key[1]).first
              LOGGER.debug "+++ #{channel} - subscribe ### Found User #{comm_port.user.id} for Client #{client_id}. comm_port.unsubscribe_ts = #{comm_port.unsubscribe_ts}"
              if comm_port.unsubscribe_ts.present?
                msg = { type: :unsubscribed_notification, old_client_id: comm_port.current_faye_client_id, seconds_ago: ((DateTime.now - comm_port.unsubscribe_ts.to_datetime) * 24 * 60 * 60).to_i }
                Comm::ChannelsController.publish(channel, msg)
                comm_port.update_attributes(current_faye_client_id: client_id, unsubscribe_ts: nil)
              else
                comm_port.update_attribute(:current_faye_client_id, client_id)
              end
              # now that current_faye_client_id is set, the client can start to communicate
              # first it should register to it's own bidirectional channels
              msg = { type: :ready_notification }
              Comm::ChannelsController.publish(channel, msg)
            end
          rescue => e
            LOGGER.error "!!! #{channel} - subscribe !!! #{e.message}"
          end
        end
      end
      monitor :unsubscribe do
        LOGGER.debug "--- #{channel} - unsubscribe ### Client #{client_id}"
        subscription_enc_key = channel.match(/^\/system#{PEER_CHANNEL_PREFIX}([^\/]+)/)
        if subscription_enc_key.present?
          begin
            # store info and send to client on next subscription
            # since unsubscribed client would'n receive it here
            comm_port = CommPort.where(sys_channel_enc_key: subscription_enc_key[1]).first
            LOGGER.debug "--- #{channel} - unsubscribe ### Found User #{comm_port.user.id} for Client #{client_id}."
            comm_port.update_attribute(:unsubscribe_ts, DateTime.now)
          rescue => e
            LOGGER.error "!!! #{channel} - unsubscribe !!! #{e.message}"
          end
        end
      end
      monitor :publish do
        LOGGER.debug "### #{channel} - publish ### #{data.inspect}"
      end
    end

    channel '/talk**' do
      filter :out do
        LOGGER.debug "<<< #{message}."
        publish_data = message['data']
        if publish_data.present?
          chat_msg = Comm::ChannelsController.add_chat_message message['channel'], publish_data
          publish_data['chat_message_id'] = chat_msg.id if chat_msg.present?
          publish_data.delete 'fci'
        end
        pass
      end
      monitor :subscribe do
        LOGGER.debug "+++ #{channel} - subscribe ### Client #{client_id}"
      end
      monitor :unsubscribe do
        LOGGER.debug "--- #{channel} - unsubscribe ### Client #{client_id}"
      end
      monitor :publish do
        # /talk@o74s558g2 - publish ### Client  ### {"type"=>"message", "userId"=>264, "text"=>"wqeqeqw\n"}
        LOGGER.debug "### #{channel} - publish ### Client #{data['fci']} ### #{data.inspect}"
        # following code moved to filter :out since message-params might be modified due to access-restrictions
        # chat_msg = Comm::ChannelsController.add_chat_message channel, data
      end
    end

    channel '/map_events**' do
      filter :in do
        block_msg = nil
        LOGGER.debug ">>> #{message}. (self: #{self.hash} / #{self.object_id})"
        if message['channel'].match(/^\/meta\/subscribe/).present?
          block_msg = Comm::ChannelsController.check_subscribe_permission message
        end
        if block_msg.nil?
          pass
        else
          block block_msg
        end
      end
      filter :out do
        LOGGER.debug "<<< #{message}."
        publish_data = message['data']
        if publish_data.present?
          begin
            case publish_data['type']
            when 'click'
              unless publish_data['address'].present?
                begin
                  location = Location.new(latitude: publish_data['lat'], longitude: publish_data['lng'])
                  location = nearby_location location, 10
                  if location.persisted?
                    address = shorten_address location
                    publish_data['locationId'] = location.id
                  else
                    geo = Geocoder.search([publish_data['lat'], publish_data['lng']])
                    address = geo[0].address
                    parts = address.split(',')
                    if parts.size >= 3
                      address = parts.drop([parts.size - 2, 2].min).join(',').strip
                    end
                  end
                  LOGGER.debug "<<< providing reverse-geocoding-service: #{address}"
                  publish_data['address'] = address
                rescue => e
                  LOGGER.error "!!!!!! map_events - filter-out: [click] #{e.message}"
                end
              end
            end
          rescue => e
            LOGGER.error "!!!!!! map_events - filter-out: #{e.message}"
          end
        end
        pass
      end
      monitor :subscribe do
        LOGGER.debug "+++ #{channel} - subscribe ### Client #{client_id}"
      end
      monitor :unsubscribe do
        LOGGER.debug "--- #{channel} - unsubscribe ### Client #{client_id}"
      end
      monitor :publish do
        LOGGER.debug "### #{channel} - publish ### Client #{client_id} ### #{data.inspect}"
        begin
          case data['type']
          when 'click'
            user = User.where(id: data['userId']).first
            if user.present?
              location = nearby_location Location.new(latitude: data['lat'], longitude: data['lng']), 10
              if location.persisted?
                user.snapshot.location = location
                user.snapshot.lat = nil
                user.snapshot.lng = nil
                user.snapshot.address = nil
              else
                user.snapshot.location = nil
                user.snapshot.lat = location.latitude
                user.snapshot.lng = location.longitude
                user.snapshot.address = shorten_address location, true
              end
              user.snapshot.save!
            end
          end
        rescue => e
          LOGGER.error "!!!!!! map_events - publish: #{e.message}"
        end
      end
    end

    channel '/pois**' do
      monitor :subscribe do
        LOGGER.debug "+++ #{channel} - subscribe ### Client #{client_id}"
      end
      monitor :unsubscribe do
        LOGGER.debug "--- #{channel} - unsubscribe ### Client #{client_id}"
      end
      monitor :publish do
        LOGGER.debug "### #{channel} - publish ### Client #{client_id} ### #{data.inspect}"
      end
    end
    
    channel '/radar**' do
      filter :in do
        block_msg = nil
        LOGGER.debug ">>> #{message}. (self: #{self.hash} / #{self.object_id})"
        if message['channel'].match(/^\/meta\/subscribe/).present?
          block_msg = Comm::ChannelsController.check_subscribe_permission message
        end
        if block_msg.nil?
          pass
        else
          block block_msg
        end
      end
      monitor :subscribe do
        LOGGER.debug "+++ #{channel} - subscribe ### Client #{client_id}"
      end
      monitor :unsubscribe do
        LOGGER.debug "--- #{channel} - unsubscribe ### Client #{client_id}"
      end
      monitor :publish do
        LOGGER.debug "### #{channel} - publish ### Client #{client_id} ### #{data.inspect}"
      end
    end

    private

    def self.check_subscribe_permission message
      block_msg = nil
      subscription_enc_key = message['subscription'].match(/^.+?#{PEER_CHANNEL_PREFIX}([^\/]+)/)
      if subscription_enc_key.present?
        LOGGER.debug "... found subscription_enc_key '#{subscription_enc_key[1]}'"
        begin
          user_comm_port = CommPort.where(current_faye_client_id: message['clientId']).first
          if user_comm_port.present?
            target = CommPort.where(channel_enc_key: subscription_enc_key[1]).first
            # allow self-subscription so that others can communicate with me
            granted = target.present? &&
                      (target.current_faye_client_id == message['clientId'] ||
                       target.comm_peers.where(peer_id: user_comm_port.user.id, granted_by_user: true).present?)
            if granted
              LOGGER.debug "... allow subscription on channel #{message['subscription']} for user #{user_comm_port.user.id}"
            else
              LOGGER.debug "... deny subscription on channel #{message['subscription']} for user #{user_comm_port.user.id} because grant missing"
              block_msg = 'grant required for subscription'
            end
          else
            LOGGER.debug "... deny subscription on channel #{message['subscription']} because user not signed in"
            block_msg = 'only subscribable for signed in users...'
          end
        rescue => e
          LOGGER.error "!!!!!! #{e.message}"
        end
      end
      block_msg
    end
    
    def self.add_chat_message channel, data
      chat_msg = nil
      channel_enc_key_match = channel.match(/^.+?#{PEER_CHANNEL_PREFIX}([^\/_]+)(_p2p|)/)
      if channel_enc_key_match.present?
        is_p2p = channel_enc_key_match[2] == '_p2p'
        p2p_receiver = is_p2p ? User.joins(:comm_port).where(comm_ports: {channel_enc_key: channel_enc_key_match[1]}).first : nil
        begin
          sender = User.find data['userId']
          if sender.comm_port.current_faye_client_id == data['fci']
            chat_msg = ChatMessage.create sender: sender, text: data['text'].strip, p2p_receiver: p2p_receiver
          else
            LOGGER.warn "!!! #{channel} - publish: fake user message: sender: #{sender.id} / #{sender.username}"
          end
        rescue => e
          LOGGER.error "!!! #{channel} - publish !!! #{e.message}"
        end
      end
      chat_msg
    end

    def check_read_permission channel
      channel_enc_key_match = channel.match(/^.+?#{PEER_CHANNEL_PREFIX}([^\/_]+)(_p2p|)/)
      if channel_enc_key_match.present?
        channel_enc_key = channel_enc_key_match[1]
      end
    end
  end
end
