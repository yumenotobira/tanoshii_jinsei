#!/bin/bash
bundle install --path vendor/bundle
touch means.tsv
touch covariances.tsv
bundle exec ruby reply.rb > /dev/null 2>&1 &
