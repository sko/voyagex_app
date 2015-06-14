VoyageX::Application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'auth/omniauth_callbacks',
                            registrations: "auth/registrations",
                            sessions: "auth/sessions" }
  devise_scope :user do
    match '/auth/:provider', to: 'sessions#create', via: [:get, :post], as: :authentication
    match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post], as: :authentication_callback
    match '/auth/failure', to: 'sessions#failure', via: [:get, :post]
    match '/auth/facebook/disconnect', to: 'users#disconnect_from_facebook', via: [:get, :post]
    match '/auth/twitter/disconnect', to: 'users#disconnect_from_twitter', via: [:get, :post]
  end

  mount Resque::Server, at: '/4hfg398dmmnrf/resque', as: :resque_admin
  
  mount Comm::Engine => "/comm" unless Rails.env == 'test'

  resources :users, only: [:update] do
  end
  get '/peers/:location_id', to: 'users#peers', as: :peers
  get '/unread_chat_messages', to: 'users#unread_chat_messages', as: :unread_chat_messages
  put '/chat_message_received/:id', to: 'users#chat_message_received', as: :chat_message_received
  # get '/peers/:lat/:lng', to: 'users#peers', as: :peers, :constraints => { :lat => /([0-9]+\.[0-9]+|:[a-z]+)/,
  #                                                                          :lng => /([0-9]+\.[0-9]+|:[a-z]+)/ }

  get '/location_bookmarks', to: 'main#index'
  get '/location_data/:location_id', to: 'main#location_data', as: :location_data
  get '/pois/:lat/:lng', to: 'pois#pois', as: :pois, :constraints => { :lat => /([0-9]+\.[0-9]+|:[a-z]+)/,
                                                                       :lng => /([0-9]+\.[0-9]+|:[a-z]+)/ }
  post '/sync_pois', to: 'pois#sync_pois', as: :sync_pois
  #delete '/pois/:id', to: 'pois#destroy', as: :poi_note
  match '/pull_pois', to: 'pois#pull_pois', as: :pull_pois, via: [:get, :post]
  
  get '/manifest', to: 'main#manifest', as: :manifest
  match '/set_user_detail/:detail', to: 'users#change_details', as: :set_user_detail, via: [:get, :post]
  delete '/set_user_detail/:detail', to: 'users#delete_details'
  get '/csrf', to: 'pois#csrf', as: :csrf
  get '/poi_comments/:poi_id/:poi_note_id', to: 'pois#comments', as: :poi_comments
  get '/ping/:key', to: 'comm/comm#ping', as: :comm_ping
  put '/register', to: 'comm/comm#register', as: :comm_register

  get '/test/javascript', to: 'test#javascript', as: :test_javascript

  get '/thesis', to: 'thesis#index', as: :thesis
  
  root to: 'main#index'
end
