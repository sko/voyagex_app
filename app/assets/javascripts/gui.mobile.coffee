unless window.VoyageX?
  window.VoyageX = {}
class window.VoyageX.Gui

  constructor: () ->
    window.GUI = this
    @_checkDimsTOMillis = 500
    @_orientationDims = { portrait: [], landscape: [] }
    @_checkDims = {o: null, w: -1, h: -1}
    $(window).on 'orientationchange', this.orientationChangedCB
    $(document).on 'click', '#enable_fullscreen', (event) ->
      GUI.toggleFullScreen true
      $("#fullscreen_dialog").hide();
      GUI.closeSystemMessage()
      $('#fullscreen_mode_icon_on').hide()
      $('#fullscreen_mode_icon_off').show()
    $(document).on 'click', '#disable_fullscreen', (event) ->
      $("#fullscreen_dialog").hide();
      GUI.closeSystemMessage()
      $('#fullscreen_mode_icon_on').show()
      $('#fullscreen_mode_icon_off').hide()
    $(document).on 'click', '.activate_map', (event) ->
      VIEW_MODEL.menuNavClick('map')
    $(document).on 'click', '.activate_upload', (event) ->
      VIEW_MODEL.menuNavClick('home')
    $("#system_message_popup").on 'popupafterclose', (event, ui) ->
        if window.stopSound?
          stopSound()
    $("#context_nav_tabs").tabs()
    if $.mobile
      # actually jquery-mobile should be available here
      $(document).on 'click', '.show-page-loading-msg', () ->
        $this = $( this )
        theme = $this.jqmData( "theme" ) || $.mobile.loader.prototype.options.theme
        msgText = $this.jqmData( "msgtext" ) || $.mobile.loader.prototype.options.text
        textVisible = $this.jqmData( "textvisible" ) || $.mobile.loader.prototype.options.textVisible
        textonly = !!$this.jqmData( "textonly" )
        html = $this.jqmData( "html" ) || ""
        $.mobile.loading( 'show', {
          text: msgText,
          textVisible: textVisible,
          theme: theme,
          textonly: textonly,
          html: html
          })
      $(document).on 'click', '.hide-page-loading-msg', () ->
        $.mobile.loading( "hide" )

  isMobile: () ->
    true

  showActiveState: (activeSelector = null) ->
    if APP.isOnline()
      colors = {active: '1f9600', inactive: '2c6b00'}
    else
      colors = {active: 'd91b00', inactive: '980a00'}
   #$('#menu_top button').not(':focus').css('background-color', '#'+colors.inactive)
    $('#menu_top button').css('background-color', '#'+colors.inactive)
    unless activeSelector?
      activeSelector = $('#menu_top button:focus')
    activeSelector.css('background-color', '#'+colors.active)

  showView: (view) ->
    #$('#activate_'+view.key).focus()
    this.showActiveState()
    $('#content_'+view.key).css('display', 'block')
    if view.key == 'map'
      if MC?
        MC.reload()

  hideView: (view) ->
    $('#content_'+view.key).css('display', 'none')
  
  showLoginDialog: (confirmEmailAddress = null) ->
    if confirmEmailAddress?
      $("#sign_in_flash").html("check email-account "+confirmEmailAddress+" first for confirmation-mail")
    $('#sign_in_modal').popup()
    $('#sign_in_modal').popup('open')

  viewAttachment: (url) ->
    maxWidth = Math.abs($(window).width() * 0.8)-10
    maxHeight = Math.abs($(window).height() * 0.8)-10
    $('#attachment_view_panel').html($('#attachment_view_panel_close_btn').html()+'<div class="attachment_view"><img src="'+url+'" style="max-width:'+maxWidth+'px;max-height:'+maxHeight+'px;"></div>')
    $('#open_attachment_view_btn').click()

  closeSignInDialog: () ->
    $('#sign_in_cancel').click() # data-role-popup

  closeContextNavPanel: () ->
    $("#context_nav_panel").panel("close") # data-role-panel

  closeUploadDataDialog: () ->
#     if $('#upload_comment_conrols').hasClass('ui-popup-active')
#       $('#upload_comment_conrols').removeClass('ui-popup-active').addClass('ui-popup-hidden')
#     $('#upload_comment_cancel').click()
    $("#upload_data_panel").panel("close") # data-role-panel

  closeSystemMessagePanel: () ->
    $("#system_message_panel").panel("close") # data-role-panel

  closeSystemMessagePopup: () ->
    if $('#system_message_popup-popup').hasClass('ui-popup-active')
      $('#system_message_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')

  showSystemMessage: (callback, dims = {w: -1, h: -1}, type = 'dialog') ->
    if type == 'popup'
      sMP = $('#system_message_popup')
    else
      sMP = $('#system_message_panel')
    if dims?
      unless dims.w == -1
        # dims: n % 1 === 0  ... float -> percent - else px
        # $(window).width(), $(window).height()
        if (dims.w+'').match(/\./)
          w = Math.round dims.w*$(window).width()
          h = Math.round dims.h*$(window).height()
          styleDef = "{width: "+w+"px; height: "+h+"px;}"
          styleKey = 'dim_'+w+'x'+h
        else
          styleDef = "{width: "+dims.w+"px; height: "+dims.h+"px;}"
          styleKey = 'dim_'+dims.w+'x'+dims.h
        style = $('#'+styleKey)
        unless style.length >= 1
          $("head").append("<style id="+styleKey+" type='text/css'>."+styleKey+" "+styleDef+"</style>");
        oldDims = sMP.attr('class').match(/($| )dim_([0-9]+)x([0-9]+)/)
        if oldDims?
          sMP.removeClass oldDims[0].trim()
        unless sMP.hasClass(styleKey)
          sMP.addClass(styleKey)        
    if type == 'popup'
      callback $('#system_message_as_popup')
      $('#system_message_popup_link').click()
    else
      callback $('#system_message')
      $('#open_system_message_btn').click()

  closeSystemMessage: (type = 'dialog') ->
    $('#system_message').html('')
    if type == 'popup'
      GUI.closeSystemMessagePopup()
    else
      GUI.closeSystemMessagePanel()

  orientationChangedCB: (event) -> 
    GUI.orientationChanged event

  orientationChanged: (event) -> 
    # event.orientation = portrait | landscape
    if @_orientationDims[event.orientation].length == 0
      @_checkDims.o = event.orientation
      @_checkDims.w = $(window).width()
      @_checkDims.h = $(window).height()
      @_checkDims.n = 1
      setTimeout('GUI.checkDims()', @_checkDimsTOMillis)
    else
      #if $('#context_nav_panel').hasClass('ui-panel-open')
      console.log 'orientationchange: to '+event.orientation+'; window-width = '+$(window).width()+', stored-width = '+@_orientationDims[event.orientation][0]
      #console.log 'body-width = '+$('body').width()+'; body-height = '+$('body').height()
      $('#context_nav_panel').css('width', @_orientationDims[event.orientation][0]+'px')
      $('#context_nav_panel').css('height', (@_orientationDims[event.orientation][1]-$('#context_nav_panel').offset().top)+'px')
      panelCtrlTopOff = $(window).height()- 41
      $('#panel_control_style').remove()
      $("head").append("<style id='panel_control_style' type='text/css'>#panel_control {position: fixed; top: "+panelCtrlTopOff+"px; height: 20px; z-index: 1000 !important;}</style>")
      $('#context_nav_open_icon').css('top', panelCtrlTopOff+'px')
      $('#map_style').remove()
      mapWidth = @_orientationDims[event.orientation][0]
      mapHeight = (@_orientationDims[event.orientation][1]-$('#map').offset().top)
      $("head").append("<style id='map_style' type='text/css'>#map {width:"+mapWidth+"px;height:"+mapHeight+"px;}</style>");
      if MC?
        MC.reload()

  checkDims: () ->
    console.log 'checkDims: state.w = '+@_checkDims.w+', w.width = '+$(window).width()+', state.h = '+@_checkDims.h+', w.height = '+$(window).height()
    if @_checkDims.n <= 2
      if @_checkDims.w == $(window).width() || @_checkDims.h == $(window).height()
        @_checkDims.n += 1
        setTimeout('GUI.checkDims()', @_checkDimsTOMillis)
        return null
    @_orientationDims[@_checkDims.o][0] = $(window).width()
    @_orientationDims[@_checkDims.o][1] = $(window).height()
    this.orientationChanged {orientation: @_checkDims.o}

  toggleFullScreen: (activate) ->
    if activate
      b = $('body')[0]
      if (b.requestFullscreen)
        b.requestFullscreen()
      else if (b.webkitRequestFullscreen)
        b.webkitRequestFullscreen()
      else if (b.mozRequestFullScreen)
        b.mozRequestFullScreen()
      else if (b.msRequestFullscreen)
        b.msRequestFullscreen()
      $('#fullscreen_mode_icon_on').hide()
      $('#fullscreen_mode_icon_off').show()
      @_checkDims.o = if window.orientation==0 then 'portrait' else 'landscape'
      @_checkDims.n = 1
      setTimeout('GUI.checkDims()', @_checkDimsTOMillis)
    else
      if (document.exitFullscreen) 
        document.exitFullscreen()
      else if (document.webkitExitFullscreen) 
        document.webkitExitFullscreen()
      else if (document.mozCancelFullScreen) 
        document.mozCancelFullScreen()
      else if (document.msExitFullscreen) 
        document.msExitFullscreen()
      $('#fullscreen_mode_icon_on').show()
      $('#fullscreen_mode_icon_off').hide()
      @_checkDims.o = if window.orientation==0 then 'portrait' else 'landscape'
      @_checkDims.n = 1
      setTimeout('GUI.checkDims()', @_checkDimsTOMillis)
  
  toggleHomeTab: (selected) ->
    if selected.value == 'administration'
      $('#content_help').css('display', 'none')
      $('#administration').css('display', 'block')
      $('#stats').css('display', 'none')
    else if selected.value == 'help'
      $('#content_help').css('display', 'block')
      $('#administration').css('display', 'none')
      $('#stats').css('display', 'none')
    else
      $('#content_help').css('display', 'none')
      $('#administration').css('display', 'none')
      $('#stats').css('display', 'block')

  hideAjaxLoading: () ->
    $('html').first().removeClass('ui-loading')
    $('html').first().removeClass('ui-overlay-a')
