# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

#require 'faye'
##require ::File.expand_path('../app', __FILE__)
#Faye::WebSocket.load_adapter('thin')

#use Faye::RackAdapter, :mount      => '/comm',
#                       :timeout    => 25,
#                       :map => { '/**' => Comm::ChannelsController },
#                       :engine  => {
#                                     :type  => Faye::Redis,
#                                     :host  => 'localhost'
#                                   }

run VoyageX::Application
