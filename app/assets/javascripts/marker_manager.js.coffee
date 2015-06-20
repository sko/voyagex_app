class window.VoyageX.MarkerManager

  @_SINGLETON = null

  constructor: (map) ->
    MarkerManager._SINGLETON = this
    @_map = map
    @_selectedMarker = null
    @_markers = []
    @_showSearchRadius = false
    @_selectedSearchRadius = null
    @_maxZIndex = 0
    @_userMarkerMouseOver = true

  _checkVisible: (location, samePosMarker = null) ->
    if samePosMarker == null
      samePosMarker = this.forPos location.lat, location.lng
      if samePosMarker? ||
         ((p = @_map.project(L.latLng(location.lat, location.lng)))? && (samePosMarker = this.nearByPoint(p.x, p.y, 3))?)
        if samePosMarker._flags.peer?
          this._checkVisible location, samePosMarker
    else
      # can only be user- or peer-marker
      console.log('add: moving marker top/left +3px to visibility ...')
      posPoint = @_map.project L.latLng(location.lat, location.lng)
      movedLatLng = @_map.unproject L.point(posPoint.x+3, posPoint.y+3)
      samePosMarker.target().setLatLng movedLatLng

  add: (location, callBack, flags = {isUserMarker: false, peer: null, beam: null}, meta = false) ->
    markerOps = { draggable: flags.isUserMarker||flags.beam?,\
                  riseOnHover: true }
    unless flags.isUserMarker
      if flags.peer?
        markerOps.icon = new L.Icon.Default({iconUrl: VoyageX.IMAGES_MARKER_PEER_PATH})
      else if flags.beam?
        markerOps.icon = new L.Icon.Default({iconUrl: VoyageX.IMAGES_MARKER_BEAM_PATH})
      else
        markerOps.icon = new L.Icon.Default({iconUrl: VoyageX.IMAGES_MARKER_POI_PATH})
        this._checkVisible location
    marker = L.marker([location.lat, location.lng], markerOps)
    m = new VoyageX.Marker(marker, location, flags)
    @_markers.push m
    if callBack != null
      marker.on 'click', callBack
      if flags.isUserMarker
        marker.on 'dblclick', callBack
        marker.on 'dragend', callBack
        marker.on 'mouseover', callBack
      else if flags.beam?
        marker.on 'dragend', callBack
    marker.addTo(@_map)
    if marker._zIndex > @_maxZIndex
      @_maxZIndex = marker._zIndex+1
      if @_selectedMarker != null
        @_selectedMarker.target().setZIndexOffset @_maxZIndex
    if flags.isUserMarker
      marker._icon.title = marker._leaflet_id
    else
      if flags.peer?
        marker._icon.title = flags.peer.username+' ('+flags.peer.id+')'
        #marker._icon.title = '<img src="'+flags.peer.foto.url+'" style="max-width: 35px;">'
      else
        marker._icon.title = location.address + (if m.isPoiMarker() then ' ('+APP.storage().getPoiForLocation(location.id).id+')' else '')
   #if meta then {marker: marker, isUserMarker: flags.isUserMarker, poi: APP.storage().getPoiForLocation(location.id), peer: flags.peer} else marker
    if meta then MarkerManager.metaJSON(m, {poi: APP.storage().getPoiForLocation(location.id), peer: flags.peer}) else marker

  # replace can only be of same type (no flags). it's used to update location id after sync and poiid
  replace: (location, withLocation = null) ->
    for m, i in @_markers
      if m.location().id == location.id
        if withLocation?
          m._location = withLocation
        else
          this._removeAt i
        break

  _removeAt: (index) ->
    m =  @_markers[index]
    @_markers.splice index, 1
    popup = m.target().getPopup()
    if popup?
      if popup._isOpen
        m.target().closePopup()
      m.target().unbindPopup()
      @_map.removeLayer(popup)
    @_map.removeLayer(m.target())

  sel: (replaceMarker, lat, lng, callBack) ->
    if replaceMarker == null
      marker = this.add {lat: lat, lng: lng}, callBack, true
      @_selectedMarker = @_markers[@_markers.length - 1]
    else
      for m in @_markers
        if m.target() == replaceMarker
          @_selectedMarker = m
          break
      if @_selectedMarker?
        @_selectedMarker.setLocation {lat: lat, lng: lng}
      else
        for m, idx in @_markers
          if m.isUserMarker()
            @_markers.splice idx, 1
            break
        @_selectedMarker = new VoyageX.Marker(replaceMarker, {lat: lat, lng: lng}, {isUserMarker: true, peer: null})
        @_markers.push @_selectedMarker

    @_selectedMarker.target().setZIndexOffset @_maxZIndex        
    @_selectedMarker.target()

  get: (meta = false) ->
    if @_selectedMarker != null then (if meta then MarkerManager.metaJSON(@_selectedMarker, {poi: null, peer: null}) else @_selectedMarker.target()) else null

  meta: (leafletMarker) ->
    for m in @_markers
      if m.target() == leafletMarker
        meta = {isUserMarker: m.isUserMarker(), poi: null, peer: null}
        if m.isPeerMarker()
          meta.peer = m._flags.peer
        else
          meta.poi = APP.storage().getPoi m.location().poiId
        return meta
    null
  
  @metaJSON: (marker, options) ->
    { target: () ->
        marker.target()
      , m: marker, isUserMarker: marker.isUserMarker(), poi: options.poi, peer: options.peer }

  userMarkerMouseOver: (enable = null) ->
    if enable == null
      return @_userMarkerMouseOver
    if enable
      unless @_userMarkerMouseOver
        @_userMarkerMouseOver = true
    else
      if @_userMarkerMouseOver
        @_userMarkerMouseOver = false

  forUser: () ->
    for m in @_markers
      if m._flags.isUserMarker
        return MarkerManager.metaJSON m, {}
    null

  removeForPoi: (poiId) ->
    for m, idx in @_markers
      if m.isPoiMarker() && m.location().poiId == poiId
        this._removeAt idx
        break

  forPoi: (poiId) ->
    for m in @_markers
      if m.location().poiId == poiId
        poi = APP.storage().getPoi m.location().poiId
        return MarkerManager.metaJSON m, {poi: poi}
    null

  removeForPeer: (peerId) ->
    for m, idx in @_markers
      if m._flags.peer? && m._flags.peer.id == peerId
        this._removeAt idx
        break

  forPeer: (peerId) ->
    for m in @_markers
      if m._flags.peer? && m._flags.peer.id == peerId
        return MarkerManager.metaJSON m, {peer: m._flags.peer}
    null

  forPos: (lat, lng) ->
    for m in @_markers
      if m.target().getLatLng().lat == lat && m.target().getLatLng().lng == lng
        return m
    null

  forPositionPreview: () ->
    for m in @_markers
      if m._flags.beam?
        return MarkerManager.metaJSON m, {}
    null

  getPoiMarkers: (callback = null) ->
    pMs = []
    #for m, idx in @_markers
    maxIdx = @_markers.length - 1
    for idxSub in [0..maxIdx]
      idx = maxIdx-idxSub
      if @_markers[idx].isPoiMarker()
        if callback?
          callback @_markers[idx], pMs, idx
        else
          pMs.push @_markers[idx]
    pMs

  nearByPoint: (x, y, minNumPixels) ->
    for m in @_markers
      mPoint = @_map.project m.target().getLatLng()
      if Math.abs(mPoint.x-x) < minNumPixels && Math.abs(mPoint.y-y) < minNumPixels
        return m
    null

  searchBounds: (radiusMeters, map) ->
    if @_selectedSearchRadius != null
      map.removeLayer(@_selectedSearchRadius)
    if radiusMeters <= 0
      return null

    lat = @_selectedMarker.target().getLatLng().lat
    lng = @_selectedMarker.target().getLatLng().lng
    
    sBs = UTIL.searchBounds lat, lng, radiusMeters

    @_selectedSearchRadius = L.rectangle([[sBs.lat_north, sBs.lng_east],
                                          [sBs.lat_south, sBs.lng_west]], {color: '#ff7800', weight: 1})
    @_selectedSearchRadius.addTo(map);
    sBs

  toString: (leafletMarker, meta = null) ->
    unless meta?
      meta = this.meta leafletMarker
    if meta.isUserMarker
      'user_' + leafletMarker._leaflet_id
    else
      'poi['+meta.poi.id+']_' + leafletMarker._leaflet_id

  @instance: () ->
    @_SINGLETON

class VoyageX.Marker

  constructor: (marker, location, flags) ->
    @_target = marker
    @_location = location
    @_flags = flags

  target: ->
    @_target

  location: ->
    @_location

  setLocation: (location) ->
    @_location = location
    @_target.setLatLng(L.latLng(location.lat, location.lng))

#  poi: ->
#    #locations = eval("(" + localStorage.getItem(storeKey) + ")")
#    if @_location.poiId? then getPoi(@_location.poi) else APP.storage().getPoiForLocation(@_location.id)

  isUserMarker: ->
    @_flags.isUserMarker

  isPeerMarker: ->
    @_flags.peer?

  isPoiMarker: ->
    !(this.isUserMarker() || this.isPeerMarker() || @_flags.beam?)
