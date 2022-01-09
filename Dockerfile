FROM ruby:3.1.0-bullseye AS sibrowser_base

RUN apt-get update && apt-get -y install postgresql-client-13

WORKDIR /app

## Full installation
FROM sibrowser_base AS sibrowser_full

ARG RAILS_ENV

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

COPY . .

RUN if [ "x$RAILS_ENV" = "xproduction" ]; then \
    SECRET_KEY_BASE="$(openssl rand -base64 32)" bundle exec rake assets:precompile ; \
fi

CMD bundle exec rails server
