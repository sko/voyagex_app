class window.VoyageX.ChatControl

  @_SINGLETON = null

  constructor: () ->
    ChatControl._SINGLETON = this
    window.CHAT = this
    $('#message').on 'keyup', (event) ->
      if (event.which == 13 || event.keyCode == 13)
        event.preventDefault()
        publishText = $(this).val().replace(/\s*$/,'')
        unless publishText.trim() == ''
          CHAT._bcChatMessage(publishText)
          VoyageX.View.addChatMessage { text: $('#message').val() }
  
  # called when chat-window is initialized
  addP2PMsgInput: (msgInputSelector) ->
    msgInputSelector.on 'keyup', (event) ->
      if (event.which == 13 || event.keyCode == 13)
        event.preventDefault()
        CHAT.sendP2PChatMessage $(event.target)#==msgInputSelector
  
  sendP2PChatMessage: (msgInputSelector) ->
    publishText = msgInputSelector.val().replace(/\s*$/,'')
    unless publishText.trim() == ''
      peerChatContainer = msgInputSelector.closest('div[id^=peer_popup_]').first()
      peerId = parseInt peerChatContainer.attr('id').match(/[0-9]+$/)[0]
      peer = Comm.StorageController.instance().getUser peerId
      CHAT._p2pChatMessage(peer, publishText)
      VoyageX.View.addChatMessage { text: $('#p2p_message_'+peerId).val() }, true, {peer: peer, chatContainer: peerChatContainer, msgInput: msgInputSelector}

  initBCChatMessages: () ->
    conference = APP.storage().getChat()
    entries = []
    if conference?
      entryKeys = Object.keys(conference).sort()
      for entryKey, i in entryKeys
        entries.push conference[entryKey]
        userId = parseInt Object.keys(conference[entryKey])[0]
        user = APP.storage().getUser userId
        message = {peer: user, text: conference[entryKey][userId]}
        VoyageX.View.addChatMessage message, user.id == APP.user().id
    entries

  initP2PChatMessages: (peer, messages) ->
    chat = APP.storage().getChat peer
    if chat?
      # msgKeys = Object.keys(chat).sort()
      # for msgKey, i in msgKeys
      #   messages.push chat[msgKey]
      entryKeys = Object.keys(chat).sort()
      for entryKey, i in entryKeys
        userId = parseInt Object.keys(chat[entryKey])[0]
        from = if userId == peer.id then peer else APP.user()
        messages.push {from: from, text: chat[entryKey][userId]}
    messages

  _bcChatMessage: (messageText) ->
    APP.storage().addChatMessage messageText, APP.user()
    APP._comm.send('/talk', {type: 'message',\
                             userId: APP.userId(),\
                             text: messageText})

  _p2pChatMessage: (peer, messageText) ->
    APP.storage().addChatMessage messageText, peer, APP.user()
    APP._comm.send('/talk', {
                              type: 'p2p-message' 
                              userId: APP.userId() 
                              text: messageText
                            }, peer)

  _talkCB: (message) ->
    peer = APP.storage().getUser parseInt(message.userId)
    APP.model().chatMessageReceived message.chat_message_id, peer
    APP.storage().addChatMessage message.text, peer, if message.type == 'p2p-message' then peer else null
    delete message.userId
    message['peer'] = peer
    APP._view._talkCB message

  addPoiLink: (chatType, poiId) ->
    if chatType == 'p2p'
      peerMarkerMeta = APP.getOpenPopupMarker true
      popup = $(peerMarkerMeta.target()._popup._container)
      textInput = $('#p2p_message_'+peerMarkerMeta.peer.id)
      textInput.insertAtCursor('{{'+poiId+'}}')
    else
      textInput = $('#message')
      textInput.insertAtCursor('{{'+poiId+'}}')
