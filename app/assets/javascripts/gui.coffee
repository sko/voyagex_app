unless window.VoyageX?
  window.VoyageX = {}
class window.VoyageX.Gui

  constructor: () ->
    window.GUI = this
    ############################### popup ###
    # signUpDialog
    @_allSignUpFields = $([]).add($("#auth_email")).add($("#auth_password")).add($("#auth_password_confirmation"))
    @signUpDialog = $("#sign_up_modal").dialog({
          autoOpen: false,
          height: Math.abs($(window).height() * 0.7),
          width: Math.abs($(window).width() * 0.3),
          modal: true,
          buttons: {
            "Create an account": GUI._addUser,
            Cancel: () ->
              GUI.signUpDialog.dialog("close")
          },
          close: () ->
            $("#new_user")[0].reset()
            GUI._allSignUpFields.removeClass("ui-state-error")
            $("#sign_up_error").html('')
        })
    ############################### popup ###
    # signInDialog
    @_allSignInFields = $([]).add($("#auth_signin_email")).add($("#auth_signin_password"))
    @signInDialog = $("#sign_in_modal").dialog({
          autoOpen: false,
          height: Math.abs($(window).height() * 0.7),
          width: Math.abs($(window).width() * 0.3),
          modal: true,
          buttons: {
            "Sign In": GUI._signInUser,
            Cancel: () ->
              GUI.signInDialog.dialog("close")
          },
          close: () ->
            $("#new_session")[0].reset()
            GUI._allSignInFields.removeClass("ui-state-error")
            $("#sign_in_error").html('')
        })
    ############################### popup ###
    # contextNavPanel
    @contextNavPanel = $("#context_nav_panel").dialog({
          autoOpen: false,
          height: Math.abs($(window).height() * 0.8),
          width: Math.abs($(window).width() * 0.5),
          top: ($(window).height()-Math.abs($(window).height() * 0.8))+'px',
          left: '0px',
          show: { effect: "drop", duration: 500 },
          hide: { effect: "fade", duration: 500 },
          modal: true
        })
    ############################### popup ###
    # uploadDataDialog
    @uploadDataDialog = $("#upload_data_conrols").dialog({
          autoOpen: false,
          height: Math.abs($(window).height() * 0.8),
          width: Math.abs($(window).width() * 0.5),
          modal: true
        })
    ############################### popup ###
    # attachmentViewPanel
    @attachmentViewPanel = $("#attachment_view_panel").dialog({
          autoOpen: false,
          height: Math.abs($(window).height() * 0.8),
          width: Math.abs($(window).width() * 0.5),
          modal: true
        })
    ############################### popup ###
    # systemMessagePanel | systemMessagePopup
    @systemMessagePanel = $("#system_message_panel").dialog({
          #dialogClass: "no-close",
          autoOpen: false,
          height: Math.abs($(window).height() * 0.3),
          width: Math.abs($(window).width() * 0.25),
          modal: true
        })
    @systemMessagePopup = $("#system_message_popup").dialog({
          #dialogClass: "no-close",
          autoOpen: false,
          height: Math.abs($(window).height() * 0.3),
          width: Math.abs($(window).width() * 0.25),
          modal: true
        })

    $("#context_nav_panel").tabs()
  
  _addUser: () ->
    $("#new_user").submit()
    GUI.signUpDialog.dialog("close")
    return true
  
  _signInUser: () ->
    $("#new_session").submit()
    GUI.signInDialog.dialog("close")
    return true

  isMobile: () ->
    false

  showActiveState: (activeSelector = null) ->
    if APP.isOnline()
      color = '1f9600'
    else
      color = 'd91b00'
    $('#network_state_view').css('background-color', '#'+color)

  showView: (view) ->
    if !$('#menu_'+view.key).hasClass('active')
      $('#menu_'+view.key).addClass('active')
    $('#content_'+view.key).css('display', 'block')

  hideView: (view) ->
    if $('#menu_'+view.key).hasClass('active')
      $('#menu_'+view.key).removeClass('active')
    $('#content_'+view.key).css('display', 'none')
  
  showSignUpDialog: () ->
    @signUpDialog.dialog('open')
  
  showLoginDialog: (confirmEmailAddress = null) ->
    if confirmEmailAddress?
      $("#sign_in_flash").html("check email-account "+confirmEmailAddress+" first for confirmation-mail")
    @signInDialog.dialog('open')

  viewAttachment: (url) ->
    maxWidth = Math.abs($(window).width() * 0.5)-10
    maxHeight = Math.abs($(window).height() * 0.8)-10
    $('#attachment_view_panel').html('<div class="attachment_view"><img src="'+url+'" style="max-width:'+maxWidth+'px;max-height:'+maxHeight+'px;"></div>')
    @attachmentViewPanel.dialog('open')

  closeSignInDialog: () ->
    @signInDialog.dialog("close")

  closeContextNavPanel: () ->
    @contextNavPanel.dialog("close")

  closeUploadDataDialog: () ->
    @uploadDataDialog.dialog("close")

  closeSystemMessagePanel: () ->
    @systemMessagePanel.dialog("close")

  closeSystemMessagePopup: () ->
    @systemMessagePopup.dialog("close")

  showSystemMessage: (callback, dims = {w: -1, h: -1}, type = 'dialog') ->
    if type == 'popup'
      sMP = $('#system_message_popup')
    else
      sMP = $('#system_message_panel')
    if type == 'popup'
      callback $('#system_message_as_popup')
    else
      callback $('#system_message')
    sMP.dialog('open')
    if ! sMP.parent().hasClass('seethrough_panel')
      sMP.parent().addClass('seethrough_panel')

  closeSystemMessage: (type = 'dialog') ->
    $('#system_message').html('')
    if type == 'popup'
      GUI.closeSystemMessagePopup()
    else
      GUI.closeSystemMessagePanel()
