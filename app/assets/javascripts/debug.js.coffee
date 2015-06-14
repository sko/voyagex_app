class window.VoyageX.Debug
  
  @_SINGLETON = null
  @_MutationObserver = window.MutationObserver || window.WebKitMutationObserver

  constructor: () ->
    window.DEBUG = this
    @_mapObserver = null
    @_tilesObserver = null
    @_tileContainer = null
    $(document).ready () ->
        try
          DEBUG._mapObserver = new Debug._MutationObserver(Debug.subTreeModifiedCB)
          #DEBUG._mapObserver.observe($('#map')[0], { childList: true })
        catch error
          console.log('no mutation-observer-support', error)
        #$("element-root").bind("DOMSubtreeModified", Debug.subTreeModifiedCB)

  @subTreeModifiedCB: (mutations) ->
    for record in mutations
      if record.target.id == 'map'
        for element in record.addedNodes
          if element.getAttribute('class') == 'leaflet-map-pane'
            tileContainers = $(element).find('.leaflet-tile-container:parent')
            for tC in tileContainers
              if $(tC).children().length >= 1
                DEBUG._tileContainer = tC
                DEBUG._mapObserver.observe(tC, { childList: true })
                DEBUG._tilesObserver = new Debug._MutationObserver(Debug.subTreeModifiedCB)
                tiles = $(tC).find('.leaflet-tile')
                for tile in tiles
                  DEBUG._tilesObserver.observe(tile, { attributes: true })
                break
      else if record.target == DEBUG._tileContainer
        for element in record.addedNodes
          console.log('tile added '+element.getAttribute('style').match(/left:[^;]+/)+'; '+element.getAttribute('style').match(/top:[^;]+/))
          DEBUG._tilesObserver.observe(element, { attributes: true })
      else if record.target.getAttribute('class') == 'leaflet-tile'
        # record.target.src
        console.log('tile-src set to '+record.target.src+', '+record.target.getAttribute('style').match(/left:[^;]+/)+'; '+record.target.getAttribute('style').match(/top:[^;]+/))

  @instance: () ->
    @_SINGLETON

if DEBUG
  new VoyageX.Debug()