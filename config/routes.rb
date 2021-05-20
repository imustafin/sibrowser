Rails.application.routes.draw do
  root 'packages#index'

  resources :packages, only: [:index, :show]
end
