module Comm
  class CommController < ::ActionController::Base  
    include ::AuthUtils
    include ::ApplicationHelper
    include ::UserHelper

    def ping
      msg = { ping_key: params[:key], commit_hash: Commit.latest.hash_id }
      if params[:flags].present?
        if params[:flags].include? 'user'
          user = tmp_user
          last_loc = last_location user
          msg[:user] = user_json user
          msg[:user][:peerPort] = { sys_channel_enc_key: user.comm_port.sys_channel_enc_key,
                                    channel_enc_key: (user_signed_in? ? user.comm_port.channel_enc_key : nil) }
        end
      end
      render json: msg
    end

    # we don't subscribe the users to a channel but rather push to them (on their system-channel)
    # to subscribe on their own.
    # this way they also can have a dialog whether they are interested at all
    def register
      # also users that are not signed in can use faye - at least for the system-channel
      @user = tmp_user
      unless @user.comm_port.present?
        comm_port = CommPort.create(user: @user, channel_enc_key: enc_key, sys_channel_enc_key: enc_key)
        @user.comm_port = comm_port
      end
      if user_signed_in?
        if params[:subscribe_to_peers] == 'true'
#binding.pry
          subscribe_user_to_peers @user
        end
      end
      res = user_json @user
      res[:peerPort] = { sys_channel_enc_key: @user.comm_port.sys_channel_enc_key,
                         channel_enc_key: (user_signed_in? ? @user.comm_port.channel_enc_key : nil) }
      res.merge!({ homebaseLocationId: (@user.home_base.present? ? @user.home_base.id : -1),
                   curCommitHash: @user.snapshot.cur_commit.hash_id })

      render json: res
    end

    private

    def subscribe_user_to_peers user
      peers_data = []
      User.joins(:comm_port).where('comm_ports.channel_enc_key != ?', user.comm_port.channel_enc_key).each do |peer|
        peers_data << { channel_enc_key: peer.comm_port.channel_enc_key, user: { id: peer.id, username: peer.username } }
        # notify peer about user
        msg = { type: :subscription_notification, peers: [channel_enc_key: user.comm_port.channel_enc_key, user: { id: user.id, username: user.username }] }
        #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer.comm_port.channel_enc_key}", msg)
        comm_adapter.send :system, peer.comm_port.channel_enc_key, msg
      end
#      # notify user about peers - but user doesn't have key now
#      msg = { type: :subscription_notification, peers: peers_data }
#      Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{user.comm_port.channel_enc_key}", msg)
    end

  end
end
