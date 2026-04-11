FROM ruby:3.4.9-slim-bookworm

LABEL maintainer="takatoh"

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    pkg-config \
    imagemagick \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8

WORKDIR /app
COPY ./ ./
RUN bundle install

RUN cp config.yaml.example config.yaml
RUN bundle exec rake setup

CMD [ "./start.sh" ]
