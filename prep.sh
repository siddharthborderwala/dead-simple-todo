#!/usr/bin/env sh

bundler install

bundle exec rake db:create

bundle exec rake db:migrate
