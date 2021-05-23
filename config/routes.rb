Rails.application.routes.draw do
  scope '(:locale)' do
    root 'packages#index'
    resources :packages, only: [:index, :show]
  end
end
