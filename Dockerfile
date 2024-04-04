FROM ruby:3.3.0-slim-bookworm AS sibrowser_base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      postgresql-client-15 build-essential libpq-dev \
      libvips

WORKDIR /app

## Full installation
FROM sibrowser_base AS sibrowser_full

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

COPY . .

RUN rm -rf spec

RUN SECRET_KEY_BASE="$(openssl rand -base64 32)" bundle exec rake assets:precompile

CMD bundle exec rails server
