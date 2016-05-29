#!/bin/bash
bundle install --path vendor/bundle
bundle exec ruby reply.rb > /dev/null 2>&1 &
