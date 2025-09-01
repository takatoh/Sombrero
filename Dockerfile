FROM ruby:3.4.5-slim-bookworm

WORKDIR /app

COPY ./ ./

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    pkg-config \
    imagemagick \
  && bundle install \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8

RUN cp config.yaml.example config.yaml
RUN bundle exec rake setup

CMD [ "./start.sh" ]
