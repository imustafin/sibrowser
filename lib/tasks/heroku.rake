require 'platform-api'

namespace :heroku do
  desc "Scale sidekiq worker"
  task :scale, [:type, :quantity] do |_t, args|
    type = args[:type]
    quantity = args[:quantity]

    app_name = ENV.fetch("HEROKU_APP_NAME")
    client = PlatformAPI.connect_oauth(ENV.fetch('HEROKU_TOKEN'))

    client.formation.update(
      app_name,
      type,
      quantity: quantity
    )
  end
end
