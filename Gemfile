source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'rails', '~> 7.0'
gem 'importmap-rails', '~> 1.1'
# Use postgres as the database for Active Record
gem 'pg', '~> 1.4'
# Use Puma as the app server
gem 'puma', '~> 5.6'
gem 'turbo-rails', '~> 1.1'
gem 'stimulus-rails', '~> 1.1'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.7'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.12', '>= 1.12.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'rspec-rails', '~> 5.1'
  gem 'factory_bot_rails', '~> 6.2'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'kaminari', '~> 1.2'

gem 'tailwindcss-rails', '~> 2.0'
gem 'rubyzip', '~> 2.3'
gem 'heroicon', '~> 0.4.0'
gem 'rails-i18n', '~> 7.0'
gem 'sidekiq', '~> 6.5'
gem 'pg_search', '~> 2.3'
gem 'meta-tags', '~> 2.17'

gem 'view_component', '~> 2.62'

gem 'sprockets-rails', '~> 3.4', '>= 3.4.2'

gem 'platform-api', '~> 3.3', require: false

gem 'sentry-ruby', '~> 5.4'
gem 'sentry-rails', '~> 5.4'
gem 'sentry-sidekiq', '~> 5.3'

gem 'chartkick', '~> 4.2'

gem 'crawler_detect', '~> 1.2'
