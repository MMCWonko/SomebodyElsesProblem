FROM ruby:2.2

MAINTAINER Jan Dalheimer <jan@dalheimer.de>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

VOLUME /usr/src/app/in /usr/src/app/out
EXPOSE 80

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY sep.rb /usr/src/app/

RUN bundle install

CMD bundle exec ./sep.rb --indir /usr/src/app/in --outdir /usr/src/app/out --server 80
