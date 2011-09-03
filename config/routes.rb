Lowdown::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  resources :customers, :only => [:show, :update]
  resources :allocations, :only => [:index, :edit, :update, :new, :create]
  resources :providers, :only => [:index, :edit, :update, :new, :create]
  resources :projects, :only => [:index, :edit, :update, :new, :create]
  
  resource :admin, :only => [:index]

  devise_for :users, :controllers=>{:sessions=>"users"} do
    get "new_user" => "users#new_user"
    get "users/show_create" => "users#show_create"
    post "users/create_user" => "users#create_user"
    get "init" => "users#show_init"
    post "init" => "users#init"
    post "logout", :to => "users#sign_out"
    get "users/index" => "users#index"
    get "users/show_change_password" => "users#show_change_password"
    match "users/change_password"  => "users#change_password"
    post "users/update" => "users#update"
  end
  root :to => 'dashboard#index'

  get "dashboard/index"

  match "test_exception_notification" => "application#test_exception_notification"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  
  match ':controller(/:action(/:id(.:format)))'
end
