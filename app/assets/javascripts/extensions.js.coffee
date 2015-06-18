jQuery ->
  
  # show notification-popup on new chat-messages
  talkExtCB = (message) ->
    console.log 'got a talk - message: ' + message
 
  VoyageX.View.instance().addListener 'talk', talkExtCB
