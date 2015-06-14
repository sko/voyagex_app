window.pingKey = <%= params[:key] %>
setTimeout "VoyageX.Backend.instance().pingBackend()", VoyageX.Backend._PING_INTERVAL_MILLIS
