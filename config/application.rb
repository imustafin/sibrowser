require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sibrowser
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")


    config.x.vk_app_id = ENV['VK_APP_ID']
    config.x.vk_secret = ENV['VK_SECRET']
    config.x.vk_service = ENV['VK_SERVICE']

    config.active_record.schema_format = :sql

    MetaTags.configure do |c|
      c.title_limit = 0
      c.description_limit = 0
    end

    initializer "app_assets", after: "importmap.assets" do
      Rails.application.config.assets.paths << Rails.root.join('app') # for component sidecar js
    end

    # Sweep importmap cache for components
    config.importmap.cache_sweepers << Rails.root.join('app/components')

  end
end
