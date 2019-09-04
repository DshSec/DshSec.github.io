#!/usr/bin/env bash
set -e # halt script on error

echo 'Testing travis...'
bundle exec jekyll build
