Rails.application.routes.draw do
  devise_for :users

  # Rotas públicas
  root "home#index"

  resources :matches do
    resources :bets, only: [ :new, :create, :edit, :update ]
  end

  resources :teams, only: [] do
    member do
      get "logo_info"
    end
  end

  get "/rankings", to: "rankings#index", as: :rankings
  get "/termos", to: "static_pages#termos", as: :termos
  get "/privacidade", to: "static_pages#privacidade", as: :privacidade
  get "/sobre", to: "static_pages#sobre", as: :sobre
  get "/ajuda", to: "static_pages#ajuda", as: :ajuda
  get "/regras", to: "static_pages#regras", as: :regras
  get "/contato", to: "static_pages#contato", as: :contato
  get "up" => "rails/health#show", as: :rails_health_check

  # Namespace administrativo
  namespace :admin do
    root to: "dashboard#index"

    resources :matches do
      member do
        get "result", to: "match_results#edit", as: "result"
        patch "result", to: "match_results#update"
        post "finalize", to: "match_results#finalize"
      end
    end

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

    resources :rankings, only: [ :index, :show ]

    resources :teams do
      member do
        get :edit_players
        patch :update_players
        get :logo
        patch :update_logo
        get :logo_info
        patch :update_logo_info
        delete :remove_logo
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
