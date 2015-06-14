Faye::WebSocket.load_adapter('thin')

# console: Comm::Engine.app
module Comm
  class Engine < ::Rails::Engine
 #class Engine < ::Faye::RackAdapter
    isolate_namespace Comm
   #config.action_controller.allow_concurrency true
    # faye-rails can't work when Rack::Lock is enabled, as it will cause a deadlock on every request.
    config.app_middleware.delete Rack::Lock
    engine_params = [:development,:production].include?(Rails.env.to_sym) ? { engine: { type: Faye::Redis, host: 'localhost' } } : {}
   #engine_params = [:test].include?(Rails.env.to_sym) ? {} : { engine: { type: Faye::Redis, host: 'localhost' } }
    config.middleware.use FayeRails::Middleware, { mount: '/', timeout: 25 }.merge!(engine_params) do
    #config.app_middleware.insert_before VoyageX::Application.routes, FayeRails::Middleware, { mount: '/', timeout: 25 }.merge!(engine_params) do
      map '/**' => Comm::ChannelsController
      #map '/comm/**' => Comm::ChannelsController
      map :default => :block
    end
  end
##Faye::Logging.log_level = :debug
 #Faye.logger = lambda { |m| puts m }
end
