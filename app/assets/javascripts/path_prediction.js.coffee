class window.VoyageX.PathPrediction

  @_SINGLETON = null

  constructor: (mapControl) ->
    PathPrediction._SINGLETON = this
    @_mapControl = mapControl
    @_map = mapControl._map
    @_movePredictionDistMeters = 100
    @_movePredictionLastLatLng = null

  _checkForVerticalSkippedTiles: (tiles, tileXorYFixed, tileXorY) ->
    curTileXorY = tileXorY
    gapDiff = curTileXorY - tiles[tiles.length-1].y
    gapSize = Math.abs gapDiff
    if gapSize >= 2
      directionFactor = if gapDiff!=gapSize then 1 else -1
      for i in [0..(gapSize-2)]
        curTileXorY += (1*directionFactor)
        if this._tileIndex(tiles, tileXorYFixed, curTileXorY) == -1
          #if directionFactor == -1
          tiles.splice tiles.length-i, 0, {x: tileXorYFixed, y: curTileXorY}
          #else
          #  tiles.push {x: tileXorYFixed, y: curTileXorY}

  _stepThroughTiles: (tiles, relDist, directionFactorX, directionFactorY, state, zoom) ->
    distToTileEndX = 256
    state.dLngX -= distToTileEndX
    while state.dLngX > 0
      state.dLngX -= distToTileEndX

      state.cX += (distToTileEndX*directionFactorX)
      moveTileEndLng = @_map.unproject L.point(state.cX, state.cY), zoom
      if APP._debug
        VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([state.cLatLng, L.latLng(state.cLatLng.lat, moveTileEndLng.lng)], {color: 'blue'}).addTo(APP.map())
      distRelLat = relDist * distToTileEndX
      state.cY += (distRelLat*directionFactorY)
      moveRelLat = @_map.unproject L.point(state.cX, state.cY), zoom
      state.cLatLng = L.latLng(moveRelLat.lat, moveTileEndLng.lng)
      
      leftTileX = parseInt (state.cX-1)/256
      rightTileX = parseInt (state.cX+1)/256
      tileY = parseInt (state.cY)/256
      this._checkForVerticalSkippedTiles tiles, (if directionFactorX==1 then leftTileX else rightTileX), tileY
      if directionFactorX == 1
        this._addPredictionPathTile tiles, leftTileX, tileY
        this._addPredictionPathTile tiles, rightTileX, tileY
      else
        this._addPredictionPathTile tiles, rightTileX, tileY
        this._addPredictionPathTile tiles, leftTileX, tileY
      
      if APP._debug
        VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([L.latLng(moveTileEndLng.lat, moveTileEndLng.lng), state.cLatLng], {color: 'blue'}).addTo(APP.map())
        @_mapControl.showSelTileInfo tiles, zoom
    
    state
  
  _addPredictionPathTile: (tiles, x, y) ->
    if this._tileIndex(tiles, x, y) == -1
      tiles.push {x: x, y: y}

  _setupFirstTile: (tiles, tilePos1, pos1, directionFactorX, directionFactorY, relDist, state, zoom) ->
    # step to tile end
    distToTileEndX = Math.abs(state.cX - tilePos1.latX)
    state.dLngX -= distToTileEndX

    moveTileEndLng = @_map.unproject L.point(state.cX, state.cY), zoom
    if APP._debug
      VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([L.latLng(pos1.lat, pos1.lng), L.latLng(pos1.lat, moveTileEndLng.lng)], {color: 'blue'}).addTo(APP.map())
    
    # step down
    distRelLat = relDist * distToTileEndX
    state.cY += (distRelLat*directionFactorY)
    moveRelLat = @_map.unproject L.point(state.cX, state.cY), zoom
    # cursor after move right and down
    state.cLatLng = L.latLng(moveRelLat.lat, moveTileEndLng.lng)
    
    leftTileX = parseInt (state.cX-1)/256
    rightTileX = parseInt (state.cX+1)/256
    tileY = parseInt (state.cY)/256
    this._checkForVerticalSkippedTiles tiles, (if directionFactorX==1 then leftTileX else rightTileX), tileY
    if directionFactorX == 1
      this._addPredictionPathTile tiles, leftTileX, tileY
      this._addPredictionPathTile tiles, rightTileX, tileY
    else
      this._addPredictionPathTile tiles, rightTileX, tileY
      this._addPredictionPathTile tiles, leftTileX, tileY

    if APP._debug
      VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([L.latLng(moveTileEndLng.lat, moveTileEndLng.lng), state.cLatLng], {color: 'blue'}).addTo(APP.map())
      @_mapControl.showSelTileInfo tiles, zoom

    state
  
  _setupLastTile: (tiles, tilePos2, pos2, directionFactorX, directionFactorY, relDist, state, zoom) ->
    # last tile with tilePos2
    distToPos2X = tilePos2.latX - state.cX
    state.cX = tilePos2.latX
    moveLng = @_map.unproject L.point(state.cX, state.cY), zoom
    
    if APP._debug
      VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([state.cLatLng, L.latLng(state.cLatLng.lat, moveLng.lng)], {color: 'blue'}).addTo(APP.map())
    
    distRelLat = relDist * distToPos2X
    state.cY += (distRelLat*directionFactorY)
    moveRelLat = @_map.unproject L.point(state.cX, state.cY), zoom
    state.cLatLng = L.latLng(moveRelLat.lat, pos2.lng)

    if tiles.length >= 2
      this._checkForVerticalSkippedTiles tiles, tilePos2.x, tilePos2.y

    if this._tileIndex(tiles, tilePos2.x, tilePos2.y) == -1
      tiles.push {x: tilePos2.x, y: tilePos2.y}
    
    if APP._debug
      VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([L.latLng(moveLng.lat, moveLng.lng), state.cLatLng], {color: 'blue'}).addTo(APP.map())
      @_mapControl.showSelTileInfo tiles, zoom

    state

  _verticalOnlyTilesPath: (tiles, pos1, tilePos1, pos2, tilePos2) ->
    this._checkForVerticalSkippedTiles tiles, tilePos1.x, tilePos2.y
    if this._tileIndex(tiles, tilePos2.x, tilePos2.y) == -1
      tiles.push {x: tilePos2.x, y: tilePos2.y}
    if APP._debug
      VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([L.latLng(pos1.lat, pos1.lng), L.latLng(pos2.lat, pos1.lng)], {color: 'blue'}).addTo(APP.map())
      VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS.push L.polyline([L.latLng(pos2.lat, pos1.lng), L.latLng(pos2.lat, pos2.lng)], {color: 'blue'}).addTo(APP.map())

  # m1 = APP.markers().forPoi(36).target()
  # m2 = APP.markers().forPoi(37).target()
  # VoyageX.Main._MAP_CONTROL.tilesPathBetweenPositions({lat:m1._latlng.lat,lng:m1._latlng.lng},{lat:m2._latlng.lat,lng:m2._latlng.lng}, 13)
  tilesPathBetweenPositions: (pos1, pos2, zoom) ->
    tilePos1 = @_mapControl.tileForPosition pos1.lat, pos1.lng, zoom
    tilePos2 = @_mapControl.tileForPosition pos2.lat, pos2.lng, zoom
    distLngMeters = L.latLng(pos1.lat, pos1.lng).distanceTo L.latLng(pos1.lat, pos2.lng)
    distLatMeters = L.latLng(pos1.lat, pos2.lng).distanceTo L.latLng(pos2.lat, pos2.lng)
    relDist = distLatMeters / distLngMeters
    distLngX = Math.abs(tilePos2.latX - tilePos1.latX)
    tileSideMeters = @_mapControl.tileLengthToMeters zoom
    cursorX = 0
    cursorY = 0
    cursorLatLng = null
    
    tiles = []
    tiles.push {x: tilePos1.x, y: tilePos1.y}
    
    if VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS?
      for line in VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS
        @_map.removeLayer line
    window.VoyageX.DEBUG_PREDICTION_PATH_TILE_STEPS = []
    
    cursorY = tilePos1.latY # y of pos1
    if pos2.lat > pos1.lat
      if pos2.lng > pos1.lng
        cursorX = (tilePos1.x+1)*256 # end-x of tile right direction
        if cursorX > tilePos2.latX
          this._verticalOnlyTilesPath tiles, pos1, tilePos1, pos2, tilePos2
          directionFactorX = 0
        else
          directionFactorX = 1
          directionFactorY = -1
          directionFactorYLast = -1
      else
        cursorX = tilePos1.x*256 # end-x of tile left direction
        if cursorX < tilePos2.latX
          this._verticalOnlyTilesPath tiles, pos1, tilePos1, pos2, tilePos2
          directionFactorX = 0
        else
          directionFactorX = -1
          directionFactorY = -1
          directionFactorYLast = 1
    else
      if pos2.lng > pos1.lng
        cursorX = (tilePos1.x+1)*256 # end-x of tile right direction
        if cursorX > tilePos2.latX
          this._verticalOnlyTilesPath tiles, pos1, tilePos1, pos2, tilePos2
          directionFactorX = 0
        else
          directionFactorX = 1
          directionFactorY = 1
          directionFactorYLast = 1
      else
        cursorX = tilePos1.x*256 # end-x of tile left direction
        if cursorX < tilePos2.latX
          this._verticalOnlyTilesPath tiles, pos1, tilePos1, pos2, tilePos2
          directionFactorX = 0
        else
          directionFactorX = -1
          directionFactorY = 1
          directionFactorYLast = -1
    
    unless directionFactorX == 0
      state = this._setupFirstTile tiles, tilePos1, pos1, directionFactorX, directionFactorY, relDist, {dLngX: distLngX, cX: cursorX, cY: cursorY, cLatLng: cursorLatLng}, zoom
      distLngX = state.dLngX
      cursorX = state.cX
      cursorY = state.cY
      cursorLatLng = state.cLatLng
      
      state = this._stepThroughTiles tiles, relDist, directionFactorX, directionFactorY, {dLngX: distLngX, cX: cursorX, cY: cursorY, cLatLng: cursorLatLng}, zoom
      cursorX = state.cX
      cursorY = state.cY
      cursorLatLng = state.cLatLng
      
      state = this._setupLastTile tiles, tilePos2, pos2, directionFactorX, directionFactorYLast, relDist, {cX: cursorX, cY: cursorY, cLatLng: cursorLatLng}, zoom

    if APP._debug
      @_mapControl.showSelTileInfo tiles, zoom
    tiles

  _tileIndex: (tiles, x, y) ->
    maxIdx = tiles.length-1
    for i in [0..maxIdx]
      if tiles[maxIdx-i].x == x && tiles[maxIdx-i].y == y
        return maxIdx-i
    -1

  _pathPredictionOnPosSelect: () ->
    #this._setRealPosition {coords: {longitude: lat, latitude: lng}}, true
    if this._movePredictionLastLatLng == null
      this._movePredictionLastLatLng = {lat: APP._realPosition.lat, lng: APP._realPosition.lng}
    else
      this.cacheTiles()

  # 
  cacheTiles: () ->
    dist = L.latLng(this._movePredictionLastLatLng.lat, this._movePredictionLastLatLng.lng).distanceTo L.latLng(APP._realPosition.lat, APP._realPosition.lng)
    if dist >= 100
      predictDistMeters = APP.user().searchRadiusMeters
      distFactor = predictDistMeters / dist

      headingLat = APP._realPosition.lat - this._movePredictionLastLatLng.lat
      headingLng = APP._realPosition.lng - this._movePredictionLastLatLng.lng

      curLatLng = {lat: APP._realPosition.lat, lng: APP._realPosition.lng}
      #predictedLatLng = L.latLng(APP._realPosition.lat + distFactor*headingLat, APP._realPosition.lng + distFactor*headingLng)
      predictedLatLng = {lat: APP._realPosition.lat + distFactor*headingLat, lng: APP._realPosition.lng + distFactor*headingLng}
      
      if APP._debug
        unless VoyageX.DEBUG_PREDICTION_PATHS?
          window.VoyageX.DEBUG_PREDICTION_PATHS = []
        VoyageX.DEBUG_PREDICTION_PATHS.push {done: L.polyline([L.latLng(this._movePredictionLastLatLng.lat, this._movePredictionLastLatLng.lng), L.latLng(APP._realPosition.lat, APP._realPosition.lng)], {color: 'green'}).addTo(APP.map()),\
                                             pred: L.polyline([L.latLng(APP._realPosition.lat, APP._realPosition.lng), predictedLatLng], {color: 'yellow'}).addTo(APP.map())}
        m1 = APP.getUserMarker()
        curLatLng = {lat: m1._latlng.lat, lng: m1._latlng.lng}
        marker = APP.markers().forPositionPreview()
        if marker?
          marker.m.setLocation L.latLng(predictedLatLng.lat, predictedLatLng.lng)
          m2 = marker.target()
        else
          m2 = APP.markers().add L.latLng(predictedLatLng.lat, predictedLatLng.lng), (event) ->
              switch event.type
                when 'click'
                  `;`
                else
                  # drag
                  m1 = APP.getUserMarker()
                  m2 = event.target
                  VoyageX.DEBUG_PREDICTION_PATHS.push {done: null,\
                                                       pred: L.polyline([m1._latlng, m2._latlng], {color: 'yellow'}).addTo(APP.map())}
                  this.tilesPathBetweenPositions({lat:m1._latlng.lat,lng:m1._latlng.lng},{lat:m2._latlng.lat,lng:m2._latlng.lng}, APP.map().getZoom())
                  #TODO: enable cachetiles with drag and droop - reset _movePredictionLastLatLng and then APP.cacheTiles()
            , {isUserMarker: false, beam: true}
      
      #this.tilesPathBetweenPositions({lat:m1._latlng.lat,lng:m1._latlng.lng},{lat:m2._latlng.lat,lng:m2._latlng.lng}, APP.map().getZoom())
      tiles = this.tilesPathBetweenPositions({lat:curLatLng.lat,lng:curLatLng.lng},{lat:predictedLatLng.lat,lng:predictedLatLng.lng}, APP.map().getZoom())
      for tile in tiles
        # view = {zoom: APP.map().getZoom(),\
        #         tile: {row: tile.y, column: tile.x},\
        #         subdomain: MC._mapOptions['subdomains'][0]}
        # cachedTileUrl = VoyageX.MapControl.drawTile view, {default: true}
        this.cacheTile tile, APP.map().getZoom()
      this._movePredictionLastLatLng = {lat: APP._realPosition.lat, lng: APP._realPosition.lng}

  cacheTile: (tile, zoom) ->
    view = {zoom: zoom,\
            tile: {row: tile.y, column: tile.x},\
            subdomain: MC._mapOptions['subdomains'][0]}
    cachedTileUrl = VoyageX.MapControl.drawTile view, {default: true}

  clearPredictionPaths: (lastOneToo = false) ->
    if VoyageX.DEBUG_PREDICTION_PATHS?
      for entry, i in VoyageX.DEBUG_PREDICTION_PATHS
        if entry.done?
          APP.map().removeLayer entry.done
        APP.map().removeLayer entry.pred
