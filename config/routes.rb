CmsRws::Application.routes.draw do


  devise_for :users, controllers: {:sessions => "user_sessions"}
  mount Approval::Engine, at: "/approval"
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
  #get "profile" => "players#profile"
  get "reset_pin" => "players#reset_pin"
  get "create_pin" => "players#create_pin"
  post "reset_pin" => "players#do_reset_pin"
  get "inactivated" => "players#player_not_activated"
  post "lock_account" => "players#lock"
  post "unlock_account" => "players#unlock"
  post "update" => "players#update"

  get 'fund_in' => 'deposit#new'
  # post 'fund_in' => 'deposit#create'
  match "deposit" => "deposit#create", via: [:get, :post]

  get 'fund_out' => 'withdraw#new'
  # post 'fund_out' => 'withdraw#create'
  match "withdraw" => "withdraw#create", via: [:get, :post]

  post 'void_deposit' => 'void_deposit#create'
  post 'void_withdraw' => 'void_withdraw#create'
  post 'void_manual_deposit' => 'void_deposit#create'
  post 'void_manual_withdraw' => 'void_withdraw#create'
  #get 'credit_deposit' => 'credit_deposit#new'
  #post 'credit_deposit' => 'credit_deposit#create'

  #get 'credit_expire' => 'credit_expire#new'
  #post 'credit_expire' => 'credit_expire#create'

  get 'print'=> 'player_transactions#print'
  get 'reprint'=> 'player_transactions#reprint'
  get 'transactions' => 'player_transactions#index'
  get 'search_transactions' => 'player_transactions#search'
  post 'search_transactions' => 'player_transactions#do_search'
  get 'index' => 'player_transactions#index'
  get 'approval' => 'transaction_approvals#index'
  get 'search_current_ac_date_by_casino' => 'front_money#search_current_accounting_date_by_casino_id'
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

  get 'machines/current_location' => 'machines#current_location'
  get 'machines/current_casino' => 'machines#current_casino'


  post 'get_player_info' => 'player_infos#get_player_info'
  post 'retrieve_player_info' => 'player_infos#retrieve_player_info'
  post 'retrieve_player_info_ppms' => 'player_infos#retrieve_player_info_ppms'
  get 'get_player_currency' => 'player_infos#get_player_currency'
  get 'is_test_mode_player' => 'player_infos#is_test_mode_player'
  post 'lock_player' => 'internal_requests#lock_player'
  post 'internal_lock_player' => 'internal_requests#internal_lock_player'
  post 'internal_unlock_player' => 'internal_requests#internal_unlock_player'

  get 'validate_token' => 'tokens#validate'
  get 'internal_validate_token' => 'internal_requests#validate'
  post 'keep_alive' => 'tokens#keep_alive'
  get 'discard_token' => 'tokens#discard'
  post 'keep_alive_ppms' => 'tokens#keep_alive_ppms'
  get 'discard_token_ppms' => 'tokens#discard_ppms'

  get 'validate_machine_token' => 'machines#validate'

  #get 'search_lock_histories' => 'lock_histories#search'
  #post 'search_lock_histories' => 'lock_histories#do_search'

  #get 'search_pin_histories' => 'pin_histories#search'
  #post 'search_pin_histories' => 'pin_histories#do_search'

  post 'kiosk_login' => 'kiosk#kiosk_login'
  post 'validate_deposit' => 'kiosk#validate_deposit'
  post 'deposit' => 'kiosk#deposit'
  post 'withdraw' => 'kiosk#withdraw'

  post 'internal_deposit' => 'kiosk#internal_deposit'
  post 'exception_deposit' => 'kiosk#exception_deposit'
  post 'exception_withdraw' => 'kiosk#exception_withdraw'
  get 'search_account_activities' => 'account_activities#search'
  get 'do_search_account_activities' => 'account_activities#do_search'
  namespace :excels do
    get 'account_activities'
    get 'player_balance_report'
  end

  get 'search_player_balance_reports' => 'player_balance_reports#search'
  get 'do_search_player_balance_reports' => 'player_balance_reports#do_search'

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
  #mount Approval::Engine, at: "/approval"
  match '*unmatched', :to => 'application#handle_route_not_found', via: :get
end
