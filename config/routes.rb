# config/routes.rb
Rails.application.routes.draw do
  # Configuração principal do Devise (fora do namespace admin)
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Rotas públicas
  root "home#index"

  resources :matches do
    resources :bets, only: [:new, :create, :edit, :update]
  end

  resources :teams, only: [] do
    member do
      get "logo_info"
    end
  end

  # Rotas estáticas
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
    get "users/index"
    get "bets/index"
    root to: "dashboard#index"
    
    # Rotas customizadas do dashboard
    post 'refresh_cache', to: 'dashboard#refresh_cache', as: :refresh_cache
    get 'export', to: 'dashboard#export', as: :export
    get '/leaderboard', to: 'rankings#index', as: :leaderboard

    # Resources com rotas customizadas
    resources :matches do
      member do
        get "result", to: "match_results#edit", as: "result"
        patch "result", to: "match_results#update"
      end
    end

    resources :rounds do
      member do
        patch :finalize
      end
    end

    resources :championships do
      member do
        get :edit_teams
        patch :update_teams
        get :edit_rounds
        patch :update_rounds
        get :edit_matches
        patch :update_matches
      end
    end

    resources :bets do
      member do
        get :edit_status
        patch :update_status
        get :edit_result
        patch :update_result
      end
    end

    resources :rankings
      
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

    resources :players do
      member do
        get :edit_stats
        patch :update_stats
      end
    end

    resources :users do
      member do
        get :edit_password
        patch :update_password
      end
    end
  end
end