FROM ruby:3.2.9-bookworm

WORKDIR /app

COPY ./ ./

RUN apt-get update \
  && apt-get install \
  && bundle install \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8

RUN cp config.yaml.example config.yaml
RUN bundle exec rake setup

CMD [ "./start.sh" ]
