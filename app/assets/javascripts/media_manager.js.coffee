class window.VoyageX.MediaManager

  @_SINGLETON = null

  constructor: () ->
    MediaManager._SINGLETON = this
    window.MEDIA_MANAGER = this
    @_localMediaStream = null
    @_mediaInputVideo = null
    @_mediaInputImage = null
    @_mediaInputCanvas = null
    @_selectedCameraActive = false
    @_audioSourceIds = null
    @_curSelAudSrcIdx = -1
    @_videoSourceIds = null
    @_curSelVidSrcIdx = -1
    @_curPrefix = null
    # coffedscript would compile MediaStreamTrack.getSources? to "MediaStreamTrack.getSources != null" only
    if MediaStreamTrack? && (`MediaStreamTrack.getSources !== undefined`)
      this.initMediaSources()
    @_audioPlayer = null
    try
      AudioContext = window.AudioContext||window.webkitAudioContext;
      @_audioPlayer = new AudioContext()
    catch error
      console.log('no audio-player-support', error)
    $(document).on 'click', '#switch_camera', (event) ->
      MEDIA_MANAGER.switchCamera()
    $(document).on 'click', '#media_input_init', (event) ->
      $('#media_input_panel_show').click()
      MEDIA_MANAGER.takePhoto()
    $(document).on 'click', '#user_foto_media_input_init', (event) ->
      $('#user_foto_file_container').hide()
      $('#user_foto_cam_container').show()
      $('#user_foto_media_input_panel_show').click()
      MEDIA_MANAGER.takePhoto({capDis: 'user_foto_', current: 'user_foto_'})
    $(document).on 'click', '#media_input_capture_btn', (event) ->
      MEDIA_MANAGER.snapshot()
    $(document).on 'click', '#media_input_stop_btn', (event) ->
      MEDIA_MANAGER.stopCurrentVideo()
      if $.mobile
        MEDIA_MANAGER.closeMediaInputPanel()
    $(document).on 'click', '#user_foto_media_input_capture_btn', (event) ->
      MEDIA_MANAGER.snapshot()
    $(document).on 'click', '#user_foto_media_input_stop_btn', (event) ->
      MEDIA_MANAGER.stopCurrentVideo()
      if $.mobile
        MEDIA_MANAGER.closeMediaInputPanel()
    $(document).on 'click', '#user_foto_media_input_init_mobile', (event) ->
        MEDIA_MANAGER.userFotoMediaInputInitMobile()
    $(document).on 'click', '#user_foto_media_input_upload_btn', (event) ->
      # don't send form
      event.stopPropagation()
      event.preventDefault()
      fotoContentType = $('#user_foto_media_input_current').attr('src').match(/^data:([^;]+)/)[1]
      fotoData = $('#user_foto_media_input_current').attr('src').replace(/^data:image\/.+?base64,/,'')
      data = { foto_data: fotoData,\
               foto_content_type: fotoContentType }
      MEDIA_MANAGER.stopCurrentVideo()
      APP.model().saveUserFoto64 data, (user) ->
          $('#'+MEDIA_MANAGER._curPrefix.current+'media_input_capture').attr('src', '')
          $('#'+MEDIA_MANAGER._curPrefix.current+'media_input_current').attr('src', '')
          #$('.whoami-img').attr('src', user.foto.url)
          curU = APP.user()
          curU.foto.url = user.foto.url
          #APP.storage().saveCurrentUser curU
          USERS.refreshUserPhoto curU
          APP.view().toogleUserFotoUpload()

  initMediaSources: () ->
    MediaStreamTrack.getSources((sourceInfos) ->
      MEDIA_MANAGER._audioSourceIds = []
      MEDIA_MANAGER._videoSourceIds = []
      for sourceInfo in sourceInfos
        if (sourceInfo.kind == 'audio') 
          console.log(sourceInfo.id, sourceInfo.label || 'microphone')
          MEDIA_MANAGER._audioSourceIds.push sourceInfo.id
          MEDIA_MANAGER._curSelAudSrcIdx = 0
        else if (sourceInfo.kind == 'video') 
          console.log(sourceInfo.id, sourceInfo.label || 'camera')
          MEDIA_MANAGER._videoSourceIds.push sourceInfo.id
          MEDIA_MANAGER._curSelVidSrcIdx = 0
        else
          console.log('Some other kind of source: ', sourceInfo)
      )

  userFotoMediaInputInitMobile: () ->
    $('#user_foto_file_container').hide()
    $('#user_foto_cam_container').show()
    $('#user_foto_media_input_panel_show').click()
    this.takePhoto({capDis: '', current: 'user_foto_'})
  
  curSelectedAudioSrcIdx: () ->
    @_curSelAudSrcIdx
  
  curSelectedVideoSrcIdx: () ->
    @_curSelVidSrcIdx
  
  nextSelectedVideoSrcIdx: () ->
    if @_curSelVidSrcIdx == -1
      return -1
    if @_curSelVidSrcIdx >= @_videoSourceIds.length - 1
      0
    else
      @_curSelVidSrcIdx + 1

  switchCamera: () ->
    if @_selectedCameraActive
      this.stopCurrentVideo()
    @_curSelVidSrcIdx = this.nextSelectedVideoSrcIdx()
    this.takePhoto @_curPrefix

  closeMediaInputPanel: () ->
    $("#media_input_panel").panel("close")
    if @_curPrefix.current == ''
      $('button[value=camera]').focus()
      # reopen panel
      # TODO: which one?
      $('#open_upload_data_btn').click()
      #$('#open_upload_comment_btn').click()

  snapshot: () ->
    if @_localMediaStream? 
      this.sizeCanvas()
      ctx = @_mediaInputCanvas[0].getContext('2d')
      ctx.drawImage(@_mediaInputVideo[0], 0, 0)
      # "image/webp" works in Chrome.
      # Other browsers will fall back to image/png.
      @_mediaInputImage[0].src = @_mediaInputCanvas[0].toDataURL('image/webp')
      #mediaInputImage[0].src = mediaInputCanvas[0].toDataURL('image/png')
      #mediaInputImage.attr('src', mediaInputCanvas[0].toDataURL('image/webp'))
      $('#fileupload').attr('value', @_mediaInputImage[0].src)
      if $.mobile
        this.closeMediaInputPanel()

  takePhoto: (prefix = {capDis: '', current: ''}) ->
    if (Modernizr.getusermedia)
      @_curPrefix = prefix
      $('#'+prefix.current+'media_input_container').css('display', 'block')
      gUM = Modernizr.prefixed('getUserMedia', navigator)
      if this.curSelectedVideoSrcIdx() >= 0
        constraints = this.constraintsForMediaSource(-1, @_curSelVidSrcIdx)
      else
        constraints = {video: true}
      gUM(constraints, (stream) ->
          # this is the success-callback
          MEDIA_MANAGER._mediaInputVideo = $('#'+prefix.capDis+'media_input_capture')
          MEDIA_MANAGER._mediaInputImage = $('#'+prefix.current+'media_input_current')
          MEDIA_MANAGER._mediaInputCanvas = $('#'+prefix.capDis+'media_input_display')
          MEDIA_MANAGER._mediaInputVideo.attr('src', window.URL.createObjectURL(stream))
          #mediaInputVideo.attr('controls', true)
          #mediaInputVideo.on 'click', () ->
          #    snapshot()
          #  , false
          MEDIA_MANAGER._localMediaStream = stream
          MEDIA_MANAGER._selectedCameraActive = true
          # video.onloadedmetadata not firing in Chrome so we have to hack.
          # See crbug.com/110938.
          setTimeout(() ->
              MEDIA_MANAGER.sizeCanvas()
          , 100)
          # Note: onloadedmetadata doesn't fire in Chrome when using it with getUserMedia.
          # See crbug.com/110938.
          MEDIA_MANAGER._mediaInputVideo[0].onloadedmetadata = (e) ->
            # Ready to go. Do some stuff.
            `;`
        , (e) ->
            console.log('Reeeejected!', e)
            alert('Reeeejected!')
            if $.mobile
              $("#media_input_panel").panel("close")
              $('button[value=camera]').focus()
      )

  sizeCanvas: () ->
    @_mediaInputCanvas.attr('width', @_mediaInputVideo[0].videoWidth)
    @_mediaInputCanvas.attr('height', @_mediaInputVideo[0].videoHeight)

  constraintsForMediaSource: (audioSourceIdx, videoSourceIdx) ->
    constraints = {}
    if audioSourceIdx >= 0
      constraints.audio = {\
            optional: [{sourceId: @_audioSourceIds[audioSourceIdx]}]\
          }
      @_curSelAudSrcIdx = audioSourceIdx
    if videoSourceIdx >= 0
      constraints.video = {\
            optional: [{sourceId: @_videoSourceIds[videoSourceIdx]}]\
          }
      @_curSelVidSrcIdx = videoSourceIdx
    return constraints

  stopCurrentVideo: () ->
    @_mediaInputVideo[0].pause()
    @_localMediaStream.stop() # Doesn't do anything in Chrome.

  drawRotated: (degrees, canvas, image) ->
    context = canvas.getContext('2d')
    context.clearRect(0, 0, canvas.width, canvas.height);
    # save the unrotated context of the canvas so we can restore it later
    # the alternative is to untranslate & unrotate after drawing
    context.save();
    # move to the center of the canvas
    context.translate(canvas.width/2, canvas.height/2);
    # rotate the canvas to the specified degrees
    context.rotate(degrees*Math.PI/180);
    # draw the image
    # since the context is rotated, the image will be rotated also
    context.drawImage(image, -image.width/2, -image.width/2);
    # we’re done with the rotating so restore the unrotated context
    context.restore();

  playSound: (filePath, callback = null) ->
    if @_audioPlayer?
      audio1 = MediaManager.instance()._audioPlayer.createBufferSource()
      stopCB = () ->
        audio1.stop()
        #audio1.currentTime = 0
      bufferLoader = new BufferLoader(
        @_audioPlayer,
        [
          filePath
        ],
        (bufferList) ->
            audio1.buffer = bufferList[0]
            audio1.connect(MediaManager.instance()._audioPlayer.destination)
            if callback?
              audio1.onended = () ->
                  callback {msg: 'finished'}
            audio1.start(0)
      )
      bufferLoader.load()
      stopCB

  @instance: () ->
    @_SINGLETON
