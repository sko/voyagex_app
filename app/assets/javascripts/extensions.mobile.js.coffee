jQuery ->

  $(document).on 'click', '.activate_chat', (event) ->
    VIEW_MODEL.menuNavClick('chat')
    #if `window.stopSound !== undefined`
    if stopSound?
      stopSound()
    GUI.closeSystemMessage('popup')
  
  # $("#system_message_popup").on 'popupafterclose', (event, ui) ->
  #     stopSound()

  # show notification-popup on new chat-messages
  talkExtCB = (message) ->
    console.log 'got a talk - message: ' + message
    if window.document.getElementById('content_chat').style.display == 'none'
      window.stopSound = VoyageX.MediaManager.instance().playSound(VoyageX.SOUNDS_MSG_IN_PATH)
      #$('#system_message_popup_link').click()
      GUI.showSystemMessage (systemMessageDiv) ->
          systemMessageDiv.html $('#tmpl_message_received_popup').html()
        , null, 'popup'
  VoyageX.View.instance().addListener 'talk', talkExtCB
