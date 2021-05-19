Rails.application.routes.draw do
  root 'packages#index'

  get 'packages', to: 'packages#index'
end
