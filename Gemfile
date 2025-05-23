source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.1'

gem 'rack-cors', '~> 2.0', '>= 2.0.2'
gem 'rails', '~> 8.0'
gem 'rails-i18n', '~> 8.0'
gem 'importmap-rails', '~> 2.1'
# Use postgres as the database for Active Record
gem 'pg', '~> 1.5'
# Use Puma as the app server
gem 'puma', '~> 6.6'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5.3'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.14'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'rspec-rails', '~> 7.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'test-prof', '~> 1.4'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 3.3'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'kaminari', '~> 1.2'

gem 'tailwindcss-rails', '~> 4.2'
gem 'rubyzip', '~> 2.4'
gem 'heroicons', '~> 2.0', '>= 2.0.1'
gem 'sidekiq', '~> 8.0'
gem 'pg_search', '~> 2.3'
gem 'meta-tags', '~> 2.22'

gem 'view_component', '~> 3.21'

gem 'sprockets-rails', '~> 3.5'

gem 'platform-api', '~> 3.7', require: false

gem 'sentry-ruby', '~> 5.22'
gem 'sentry-rails', '~> 5.22'
gem 'sentry-sidekiq', '~> 5.22'

gem 'chartkick', '~> 5.1'

gem 'crawler_detect', '~> 1.2'
gem 'activerecord-import', '~> 2.1'
gem 'rack-attack', '~> 6.7'

# Using Grape for implementing SIStorage api
gem 'grape', '~> 2.3'
gem 'grape-entity', '~> 1.0', '>= 1.0.1'
gem 'grape-swagger', '~> 2.1', '>= 2.1.2'
gem 'grape-swagger-entity', '~> 0.5.5'
gem 'grape-swagger-rails', '~> 0.6.0'
