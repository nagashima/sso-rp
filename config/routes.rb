Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "home#index"

  # Direct OAuth2 test (bypass OmniAuth for state parameter testing)
  # NOTE: この具体的なルートを先に書かないと、:providerパラメータにマッチしてしまう
  get '/auth/test_state/callback', to: 'sessions#test_state_callback'

  # Authentication routes (OmniAuth automatically handles /auth/:provider)
  get '/auth/:provider/callback', to: 'sessions#omniauth_callback'
  get '/auth/failure', to: 'sessions#auth_failure'
  delete '/logout', to: 'sessions#destroy', as: :logout

  # User info display
  get '/profile', to: 'users#show', as: :profile
end
