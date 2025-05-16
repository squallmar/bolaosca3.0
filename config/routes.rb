Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Rotas públicas
  root "matches#index"
  resources :matches, except: [ :show ] do
    resources :bets, only: [ :new, :create, :update, :edit ]
  end
  get "/rankings", to: "rankings#index", as: :rankings
  get "/termos", to: "static_pages#termos", as: :termos
  get "/privacidade", to: "static_pages#privacidade", as: :privacidade
  get "up" => "rails/health#show", as: :rails_health_check
  get "/regras", to: "static_pages#regras", as: "regras"
  get "/sobre", to: "static_pages#sobre", as: "sobre"
  get "/ajuda", to: "static_pages#ajuda", as: "ajuda"
  get "/contato", to: "static_pages#contato", as: "contato"


  # Namespace administrativo
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard/index"

    resources :matches
    resources :championships, except: [ :show ] do
      member do
        get :edit_teams
        patch :update_teams
      end
    end

    resources :bets, only: [ :index, :show, :edit, :update ] do
      member do
        get :edit_status
        patch :update_status
      end
    end

    resources :rankings, only: [ :index, :show ] do
      member do
        get :edit_teams
        patch :update_teams
      end
    end

    resources :teams, except: [ :show ] do
      member do
        get :edit_players
        patch :update_players
      end
    end

    resources :players, except: [ :show ] do
      member do
        get :edit_stats
        patch :update_stats
      end
    end

    resources :users, only: [ :index, :show, :edit, :update ] do
      member do
        get :edit_password
        patch :update_password
      end
    end
  end
end
