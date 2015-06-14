class window.VoyageX.CacheStrategy

  @_SINGLETON = null

  constructor: (pathPrediction = false) ->
    CacheStrategy._SINGLETON = this
    @_pathPrediction = pathPrediction

  getLoadTileFromUrlCB: (cacheHints = null) ->
    if @_pathPrediction && ((!cacheHints?) || (!cacheHints.default))
      (view, deferredModeParams = null, cache = false) ->
          VoyageX.MapControl.loadTileFromUrl view, deferredModeParams, false
    else
      VoyageX.MapControl.loadTileFromUrl

  getEntryCreatedCB: () ->
    if @_pathPrediction
      (view, radius, deferredModeParams = null) ->
        xYZ = [view.tile.column, view.tile.row, view.zoom]
        MC._prefetchTile view, xYZ, deferredModeParams
    else
      MC._prefetchArea