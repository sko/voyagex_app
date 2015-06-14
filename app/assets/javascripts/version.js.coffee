class window.VoyageX.Version
  
  @_SINGLETON = null

  constructor: (version) ->
    oldVerisonStr = localStorage.getItem 'voyageX.version'
    oldVerison = if oldVerisonStr? then oldVerisonStr.split('.') else [-1]

  @instance: () ->
    Version._SINGLETON
