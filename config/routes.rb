CmsRws::Application.routes.draw do


  devise_for :users, controllers: {:sessions => "user_sessions"}

  devise_scope :user do
    root :to => "user_sessions#new"
    get "/login" => "user_sessions#new", :as => :login
    post '/login' => 'user_sessions#create'
    get "/logout" => "user_sessions#destroy", :as => :logout
  end

  root :to => "user_sessions#new"

  get 'home' => 'home#index'

  get "balance" => 'players#balance'
  get "search" => 'players#search' ,:as => :players_search
  post "search" => "players#do_search"
  get "profile" => "players#profile"
  get "edit" => "players#edit"
  post "lock_account" => "players#lock_account"
  post "unlock_account" => "players#unlock_account"
  post "update" => "players#update"
  resources :players

  get 'fund_in' => 'fund_in#new'
  post 'fund_in' => 'fund_in#create'

  get 'fund_out' => 'fund_out#new'
  post 'fund_out' => 'fund_out#create'
  
  get 'print'=> 'player_transactions#print'
  get 'reprint'=> 'player_transactions#reprint'
  get 'transactions' => 'player_transactions#index'
  get 'search_transactions' => 'player_transactions#search'
  post 'search_transactions' => 'player_transactions#do_search'
  get 'index' => 'player_transactions#index'

  get 'search_front_money' => 'front_money#search'
  post 'search_front_money' => 'front_money#do_search'
  resources :shifts, only: [:index] do
    collection do
      get 'new'
      get 'current'
      post 'create'
    end
  end

  resources :accounting_dates, only: [:index] do
    collection do
      get 'current'
    end
  end
  
  get 'search_audit_logs' => 'audit_logs#search'
  post 'search_audit_logs' => 'audit_logs#do_search'

  get 'list_locations' => 'locations#list'
  post 'change_location_status' => 'locations#change_status'
  get 'list_locations/:status' => 'locations#list', :as => :list_locations
  post 'add_location' => 'locations#add'
  
  get 'list_stations/:status' => 'stations#list', :as => :list_stations
  post 'create_station' => 'stations#create'
  post 'change_station_status' => 'stations#change_status'
  post 'register_terminal' => 'stations#register'
  post 'unregister_terminal' => 'stations#unregister'
  get 'stations/current/:terminal_id' => 'stations#current'
  

  get 'validate_token' => 'tokens#validate'
  post 'retrieve_player_info' => 'tokens#retrieve_player_info'
  post 'keep_alive' => 'tokens#keep_alive'
  get 'keep_eternal_alive' => 'tokens#keep_eternal_alive'
  get 'discard_token' => 'tokens#discard'

  get 'validate_terminal' => 'terminal#validate'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  match '*unmatched', :to => 'application#handle_route_not_found', via: :get
end
