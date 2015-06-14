# @unsubscribe on client:
# https://github.com/faye/faye/issues/28
# server might publish unsubscibe even if client didn't send - but the client will reconnect(resubscribe) then.
# server does this because clients don't reliably disconnect and so server has timeout.
# reproduce when setting breakpoint in client and wait

# curl -X POST http://192.168.1.4:3005/comm -H 'Content-Type: application/json' -d '{"channel":"/system@0rg94cpmy","data":{"type":"handshake", "hello":"world"}}'
class window.Comm.Comm

  @_SINGLETON = null

  client = null
  channelCallBacksJSON = null
  systemReady = false

  constructor: (channelCallBacksList, sysChannelEncKey, systemCallBack, connStateCallBack) ->
    Comm._SINGLETON = this
    @_storageController = window.Comm.StorageController.instance()

    client = new Faye.Client(document.location.origin+'/comm')
    # for debugging
    client.addExtension({ incoming: Comm._incoming, outgoing: Comm._outgoing })
    client.on 'transport:down', () ->
        connStateCallBack false
    client.on 'transport:up', () ->
        connStateCallBack true
    
    # map callbacks to channels
    Comm.channelCallBacksJSON = new Object()
    Comm.channelCallBacksJSON['system'] = { callback: systemCallBack, channel_enc_key: sysChannelEncKey }
    for pair in channelCallBacksList
      Comm.channelCallBacksJSON[pair[0].substr(1)] = { callback: pair[1], channel_enc_key: pair[2] }

    if (sysChannelEncKey == null)
      APP.register()
    else
      Comm.initSystemContext sysChannelEncKey
  
  isOnline: () ->
    client._state == client.CONNECTED
  
  isReady: () ->
    this.isOnline() && systemReady

  _queueMessage: (channel, message, peer) ->
    if (Modernizr.localstorage)
      unless message.cacheId?
        # queue only once
        console.log('queueing publish to '+channel)
        # later send: @_storageController.pop('comm.publish')
        message.cacheId = Math.round(Math.random()*1000000)
        cacheEntry = { channel: channel, message: message, peer: (if peer? then {id: peer.id, peerPort: peer.peerPort} else null) }
        @_storageController.addToList('comm.publish', 'push', cacheEntry)
    else
      alert('This Browser Doesn\'t Support Local Storage so This Message will be lost if you quit the Browser')

  _sendMessageQueue: () ->
    while (qEntry = Comm.instance()._storageController.pop('comm.publish'))?
      console.log('sending queued-publish to '+qEntry.channel)
      Comm.instance().send qEntry.channel, qEntry.message, qEntry.peer

  send: (channel, message, peer = null) ->
    unless APP.signedIn() || channel.match(/^\/?system/)
      # FIXME - mobile doesn't alert
      #alert('only whene signed-in')
      console.log 'publish to '+channel+' only when signed-in'
      return false
    # 1) client wants to publish before register-ajax-response set the enc_key
    #    1.1: store request and send after register (local storage)
    # 2) the same goes for requests when client is offline
    if peer?
      channelEncKey = if peer.peerPort? then peer.peerPort.channel_enc_key+'_p2p' else null
    else
      channelEncKey = Comm.channelCallBacksJSON[channel.substr(1)].channel_enc_key
    unless channelEncKey == null or !systemReady or !APP.isOnline()
      channelPath = channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
        channelPath += VoyageX.PEER_CHANNEL_PREFIX + channelEncKey
      if message.cacheId?
        delete message.cacheId
      message.fci = client._clientId
      client.publish(channelPath, message)
    else
      this._queueMessage channel, message, peer

  # subscribe to 1 or 2 system-cannels: /system for system-broadcasts and /system@d63zd for system-callbacks
  @initSystemContext: (sys_channel_enc_key) ->
    Comm.channelCallBacksJSON.system.channel_enc_key = sys_channel_enc_key
    channelPath = '/system'
    Comm.subscribeTo channelPath, Comm._systemSubscriptionListener
    unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
      channelPath += VoyageX.PEER_CHANNEL_PREFIX+sys_channel_enc_key
      Comm.subscribeTo channelPath, Comm._systemSubscriptionListener
    # this is done via serverside publishing to systemchannel 
    # @see ChannelsController - system:monitor
    # @see Comm.subscribeTo - subscribe-callback
    # Comm.initChannelContexts response, Comm.channelCallBacksJSON

  @resetSystemContext: () ->
    Comm.channelCallBacksJSON.system.channel_enc_key = null 
    for channel in Object.keys(Comm.channelCallBacksJSON)
      Comm.channelCallBacksJSON[channel].channel_enc_key = null
    APP.register()

  @setChannelContext: (channel, enc_key) ->
    unless channel == 'system'
      Comm.channelCallBacksJSON[channel].channel_enc_key = enc_key
      channelPath = '/'+channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
        channelPath += VoyageX.PEER_CHANNEL_PREFIX+enc_key
      # subscribe to my own events - fails because of race-conditions
      #Comm.unsubscribeFrom channelPath
      Comm.subscribeTo channelPath, Comm.channelCallBacksJSON[channel].callback

  @initChannelContexts: (initParams, channelCallBacks) ->
    Comm.subscribeTo '/ping', Comm._systemSubscriptionListener
    for channel in Object.keys(channelCallBacks)
      unless initParams.channel_enc_key?
        # only signed-in users have channel_enc_keys
        continue
      Comm.setChannelContext channel, initParams.channel_enc_key

  @hasSubscription: (channel, enc_key) ->
    unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
      channelPath = '/'+channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
        channelPath += VoyageX.PEER_CHANNEL_PREFIX+enc_key
      r = new RegExp('^\/?talk'+VoyageX.PEER_CHANNEL_PREFIX+'(.*)')
      if (m = channelPath.match(r)) && (m[1] == Comm.channelCallBacksJSON.talk.channel_enc_key)
        channelPath += '_p2p'
    client._channels.hasSubscription(channelPath)

  @subscribeTo: (channel, callBack, defaultCBMapping = true) ->
    unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
      r = new RegExp('^\/?talk'+VoyageX.PEER_CHANNEL_PREFIX+'(.*)')
      if (m = channel.match(r)) && (m[1] == Comm.channelCallBacksJSON.talk.channel_enc_key)
        channel = channel+'_p2p'
    # https://github.com/faye/faye/blob/master/javascript/protocol/client.js
    unless client._channels.hasSubscription(channel)
      if channel.match(/^\/?system/) && defaultCBMapping
        client.subscribe channel, Comm._systemSubscriptionListener
      else
        client.subscribe channel, callBack
    else
      console.log('client already subscribed to channel '+channel)

  @unsubscribeFrom: (channelPath, isReset = false) ->
    if channelPath.match(/^\/?system/) and not isReset
      return
    unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
      r = new RegExp('^\/?talk'+VoyageX.PEER_CHANNEL_PREFIX+'(.*)')
      if (m = channelPath.match(r)) && (m[1] == Comm.channelCallBacksJSON.talk.channel_enc_key)
        channelPath = channelPath+'_p2p'
    # https://github.com/faye/faye/blob/master/javascript/protocol/client.js
    if client._channels.hasSubscription(channelPath)
      # you only can unsubscribe with passing the subscription-callback(=listener)
      # otherwise faye will not perform unsubscription
      # http://faye.jcoglan.com/architecture.html #Client
      # FayeClient - channel.unbind
      if channelPath.match(/^\/?system/)
        client.unsubscribe channelPath, Comm._systemSubscriptionListener
      else
        i = channelPath.indexOf(VoyageX.PEER_CHANNEL_PREFIX)
        channel = (if i == -1 then channelPath else channelPath.substr(0, i)).substr(1)
        client.unsubscribe channelPath, Comm.channelCallBacksJSON[channel].callback
    else
      console.log('client was not subscribed to channel '+channelPath)

  @instance: () ->
    @_SINGLETON

  @_systemSubscriptionListener: (message) ->
    if message.type == 'ready_notification'
      Comm.initChannelContexts message, Comm.channelCallBacksJSON
      systemReady = true
      #Comm.instance()._sendMessageQueue()
    # since unsubscribed client will not receive anymore - but server will send this on next subscription
    # before ready_notification
    # if client disconnects by itself, then:
    # ---------- ClientExtension - outgoing Object {channel: "/meta/disconnect", clientId: "aems9kiq4i4gedw80tgjqblw8qytfyu", id: "c"}
    # ++++++++++ ClientExtension - incoming Object {id: "c", clientId: "aems9kiq4i4gedw80tgjqblw8qytfyu", channel: "/meta/disconnect", successful: true}
    # on serverside it looks the same as timeout-unsubscribe
    else if message.type == 'unsubscribed_notification'
        console.log('_systemSubscriptionListener: client '+message.old_client_id+' unsubscribed '+message.seconds_ago+' seconds ago ... (probably timedout/disconnected by server)')
        return null
    else if message.type == 'ping'
        # TODO: respond if we follow client
        console.log('_systemSubscriptionListener: client '+message.old_client_id+' sent ping.')
        return null
    Comm.channelCallBacksJSON.system.callback message

  @_incoming: (message, callback) ->
      #console.log('++++++++++ ClientExtension - incoming', message);
      callback message
  
  @_outgoing: (message, callback) ->
      #console.log('---------- ClientExtension - outgoing', message);
      callback message
