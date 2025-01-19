require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq web
  # from https://github.com/mperham/sidekiq/wiki/Monitoring#rails-http-basic-auth-from-routes
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      # Protect against timing attacks:
      # - See https://codahale.com/a-lesson-in-timing-attacks/
      # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
      # - Use & (do not use &&) so that it doesn't short circuit.
      # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(username),
        ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])
      ) & ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(password),
        ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"])
      )
    end
  end

  mount Sidekiq::Web, at: "/sidekiq"

  # Routes

  get 'admin', to: 'admin#index', as: 'admin'
  post 'admin/login', to: 'admin#login', as: 'login'
  post 'admin/logout', to: 'admin#logout', as: 'logout'

  scope 'admin' do
    get 'cat_stats', to: 'admin#cat_stats', as: 'admin_cat_stats'
  end

  scope '(:locale)', constraints: { locale: Languages.map(&:last).map(&:to_s) } do
    root 'packages#index'

    resources :packages, only: [:index, :show] do
      post :set_cat
      get :direct_download
      get :logo, format: true, defaults: { format: Si::Package::IMAGE_EXT }
    end

    resources :authors, only: [:index, :show], constraints: { id: /.+/ }

    resources :tags, only: [:index, :show], constraints: { id: /.+/ } do
      post :toggle_cat
    end

    resources :categories, only: [:index, :show]

    namespace :profile do
      get :bookmarks
    end
  end

  # SIStorage API
  scope :sistorage do
    mount Sistorage::Api => '/api'
    mount GrapeSwaggerRails::Engine => 'swagger'
  end
end
