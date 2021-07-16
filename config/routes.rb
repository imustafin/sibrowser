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

  scope '(:locale)', constraints: { locale: Languages.map(&:last).map(&:to_s) } do
    root 'packages#index'

    resources :packages, only: [:index, :show] do
      post :toggle_cat
    end

    resources :authors, only: [:show], constraints: { id: /.+/ }

    resources :tags, only: [:index, :show], constraints: { id: /.+/ } do
      post :toggle_cat
    end

    resources :categories, only: [:index, :show]
  end
end
