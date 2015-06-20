if window.VoyageX?
  window.VoyageX.Users = {}
else
  window.VoyageX = { Users: {} }

class window.VoyageX.Users
  
  @_SINGLETON = null

  constructor: () ->
    Users._SINGLETON = this
    window.USERS = this

  removePeer: (peer, callback = null) ->
    USERS.unsubscribeFromPeerChannels peer
    APP.markers().removeForPeer peer.id
    APP.storage().deletePeer peer

  checkDistance: (peer, curPeerLocation, stateChangedCB = null) ->
    curU = APP.user()
    curUSelLatLng = APP.getSelectedPositionLatLng()
    nowSecs = Math.round(new Date().getTime()/1000)
    dist = L.latLng(curUSelLatLng[0], curUSelLatLng[1]).distanceTo L.latLng(curPeerLocation.lat, curPeerLocation.lng)
    inRange = dist <= curU.searchRadiusMeters
    unless peer.distance?
      sPeer = APP.storage().getUser peer.id
      if sPeer?
        peer.distance = sPeer.distance
    if peer.distance?
      stateChanged = if inRange then !peer.distance.stateInRange else peer.distance.stateInRange
      if stateChanged
        if nowSecs - peer.distance.lastStateChange >= 20 # 60*5 # 5 minutes
          if stateChangedCB?
            stateChangedCB peer, inRange
          if peer.distance.historyQ.length >= 5
            peer.distance.historyQ.splice 0, 1
          peer.distance.historyQ.push {lSC: peer.distance.lastStateChange, sIR: peer.distance.stateInRange}
          peer.distance = {lastStateChange: nowSecs, stateInRange: inRange, historyQ: peer.distance.historyQ}
          APP.storage().saveUser peer # {id: peer.id, distance: peer.distance}
          return true
        peer.distance = {lastStateChange: nowSecs, stateInRange: inRange, historyQ: peer.distance.historyQ}
      else
        peer.distance = {lastStateChange: peer.distance.lastStateChange, stateInRange: inRange, historyQ: peer.distance.historyQ}
    else
      peer.distance = {lastStateChange: nowSecs, stateInRange: inRange, historyQ: []}
    APP.storage().saveUser peer # {id: peer.id, distance: peer.distance}
    false

  # also subscribes to peer channel if online, otherwise
  initPeer: (peer, fromSystemCB = false, callback = null) ->
    #peerPort = peer.peerPort
    #delete peer.peerPort
    lastLocation = peer.lastLocation
    delete peer.lastLocation
    # ---------------------
    poiId = lastLocation.poiId
    if poiId?
      delete lastLocation.poiId
      APP.storage().saveLocation lastLocation, {poi: {id: lastLocation.poiId}}
    else
      unless lastLocation.id?
        # this is just required locally (not in Backend) - to access peers lastLocation later
        lastLocation.id = -peer.id
      APP.storage().saveLocation lastLocation
    # ---------------------
    peer.lastLocationId = lastLocation.id
    peer.getLastLocation = () ->
        APP.storage().getLocation this.lastLocationId
    USERS.refreshUserPhoto peer, {peerPort: peer.peerPort}, (user, flags) ->
        flags.foto = user.foto
        APP.storage().saveUser user, flags
    if callback?
      callback peer
    if APP.isOnline() && APP._comm.isReady()
      USERS.subscribeToPeerChannels peer
    else
      subscribeTo.push peer
    #APP.storage().saveUser {id: #{cs.user.id}, username: '#{cs.user.username}', peerPort: {id: #{cs.id}, channel_enc_key: '#{cs.channel_enc_key'}});
    unless fromSystemCB
      APP.view().addIFollow peer
    marker = APP.getPeerMarker peer, lastLocation
    #unless marker?
    #  Main.markerManager().add location, Main._markerEventsCB

  # all users are saved since they might be author of poi-notes
  # but only contacts have their fotos stored locally as well for offline-usage
  initUser: (user) ->
    flags = user.flags||{}
    delete user.flags
    if flags.i_follow?
      USERS.initPeer user
    else
      if flags.i_want_to_follow?
        USERS.refreshUserPhoto user, {peerPort: {}}, (u, flags) ->
            APP.storage().saveUser u, {foto: u.foto}
            APP.view().addIWantToFollow u
      else
        APP.storage().saveUser user
      APP.view().addIDontFollow user
    if flags.follows_me?
      if flags.i_follow?
        # foto already stored and peerport saved
        APP.view().addFollowsMe user
      else
        USERS.refreshUserPhoto user, {peerPort: {}}, (u, flags) ->
            APP.storage().saveUser u, {foto: u.foto}
            APP.view().addFollowsMe u
    else if flags.wants_to_follow_me?
      APP.view().addWantsToFollowMe user

  initUsers: (users) ->
    #APP.view().clearFollows()
    for user in users
      USERS.initUser user

  # saveCB recommended for currentUser
  # USERS.refreshUserPhoto newU, null, (user, flags) ->
  #     APP.storage().saveCurrentUser user
  refreshUserPhoto: (user, flags = null, saveCB = null) ->
    unless flags?
      flags = { foto: user.foto }
    userPhotoUrl = Storage.Model.storedUserPhoto user
    if (typeof userPhotoUrl == 'string') 
      user.foto.url = userPhotoUrl
      if flags?
        if flags.foto? then (flags.foto.url = userPhotoUrl) else (flags.foto = {url: userPhotoUrl})
      else
        flags = {foto: {url: userPhotoUrl}}
      if saveCB?
        saveCB user, flags
      else
        APP.storage().saveUser { id: user.id, username: user.username }, flags
      if flags.peerPort?
        $('img[name=peer_photo_'+user.id+']').attr 'src', userPhotoUrl
      else
        $('.whoami-img').attr('src', userPhotoUrl)
    else if (typeof userPhotoUrl.then == 'function')
      # Assume we are dealing with a promise.
      if flags.peerPort?
        $('img[name=peer_photo_'+user.id+']').attr 'src', VoyageX.IMAGES_SWIPER_LOADING_PATH
      else
        $('.whoami-img').attr 'src', VoyageX.IMAGES_SWIPER_LOADING_PATH
      userPhotoUrl.then (url) ->
          user.foto.url = url
          if flags?
            if flags.foto? then (flags.foto.url = url) else (flags.foto = {url: url})
          else
            flags = {foto: {url: url}}
          if saveCB?
            saveCB user, flags
          else
            APP.storage().saveUser { id: user.id, username: user.username }, flags
          if flags.peerPort?
            $('img[name=peer_photo_'+user.id+']').attr 'src', url
          else
            $('.whoami-img').attr 'src', url

  updateFollow: (user, grant) ->
    if grant
      APP.view().updateFollowsMe user
    else
      APP.view().updateFollowsMe user, {denied: true}

  resetConnection: (peerId) ->
    peerChannelEncKey = $('#i_follow_'+peerId).attr('data-channelEncKey')
    USERS.unsubscribeFromPeerChannels {peerPort: {channel_enc_key: peerChannelEncKey}}
    USERS.subscribeToPeerChannels {peerPort: {channel_enc_key: peerChannelEncKey}}

  isSubscribed: (peer, channel) ->
    Comm.Comm.hasSubscription channel, peer.peerPort.channel_enc_key

  subscribeToAllPeerChannels: () ->
    if APP.isOnline() && APP._comm.isReady()
      while (peer = subscribeTo.pop())
        USERS.subscribeToPeerChannels peer

  subscribeToPeerChannels: (peer) ->
    for channel in VoyageX.Main.commChannels()
      if channel == 'system'
        continue
      channelPath = '/'+channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
        channelPath += VoyageX.PEER_CHANNEL_PREFIX+peer.peerPort.channel_enc_key
      Comm.Comm.subscribeTo channelPath, Comm.Comm.channelCallBacksJSON[channel].callback

  unsubscribeFromPeerChannels: (peer) ->
    for channel in VoyageX.Main.commChannels()
      if channel == 'system'
        continue
      channelPath = '/'+channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
        channelPath += VoyageX.PEER_CHANNEL_PREFIX+peer.peerPort.channel_enc_key
      Comm.Comm.unsubscribeFrom channelPath
