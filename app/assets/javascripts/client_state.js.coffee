# Presentation Model of current View
# when view changes _refreshView is called, which itself calls all view-cbs
class window.VoyageX.ClientState

  constructor: (initialView, guiFactory) ->
    window.VIEW_MODEL = this
    @_gui = guiFactory.create()
    if @_gui.isMobile()
      homeViews = {
                    admin: { key: 'admin' }
                    stats: { key: 'stats' }
                    help: { key: 'help' }
                  }
      @_views = {
                  map: { key: 'map' }
                  chat: { key: 'chat' }
                  home: {  key: 'home', homeViews }
                }
    else
      @_views = {
                  map: { key: 'map' }
                  chat: { key: 'chat' }
                  home: {  key: 'home' }
                  help: { key: 'help' }
                }
    @_currentViewKey = null # initialView
    this.setView @_views[initialView]
    #this._refreshView()

  _refreshView: () ->
    for viewKey in Object.keys(@_views)
      if viewKey == @_currentViewKey
        @_gui.showView @_views[viewKey]
      else
        @_gui.hideView @_views[viewKey]
  
  menuNavClick: (clickSrc) ->
    this.setView this.getView(clickSrc)
    window.location.hash = (if clickSrc == 'chat' then 'conference' else clickSrc)

  currentView: () ->
    @_views[@_currentViewKey]
  
  getView: (view) ->
    @_views[view]

  setView: (view) ->
    if @_currentViewKey == view.key
      return
    @_currentViewKey = view.key
    if view.key == 'chat'
      $('#message').val('')
      $('#message').selectRange(0)
    this._refreshView()
    # post-refresh
    if view.key == 'chat'
      if $('.chat_view').children().length == 0
        CHAT.initBCChatMessages()

  linkForView: (path, lang, params) ->
    if path.indexOf('?') != -1
      path = path.substring(1).replace(/[cl]=[^&]*/, '')+'l=' + lang + '&c=' + @_currentViewKey
    else
      path = '?l=' + lang + '&c=' + @_currentViewKey
    if params != ''
      path += ('&'+params)
    path

  toggleSearchRadiusDisplay: (selected) ->
    if selected.id == 'search_radius_display_show'
      window.showSearchRadius = true
      APP.view().showSearchRadius APP.user().searchRadiusMeters
    else
      window.showSearchRadius = false
      #VoyageX.Main.markerManager()._showSearchRadius = false
      VoyageX.Main.markerManager().searchBounds(0, APP.map())
