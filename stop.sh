#!/bin/bash
kill `ps aux | grep reply.rb | grep -v grep | awk '{print $2}'`
