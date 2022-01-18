if ENV['SENTRY_DSN']
  Sentry.init do |config|
    config.dsn = ENV.fetch('SENTRY_DSN')
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  end
end
