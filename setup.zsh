#!/usr/bin/env zsh
set -e

if ! command -v ruby >/dev/null 2>&1; then
  echo "Ruby not found. Installing via Homebrew..."
  brew install ruby
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler not found. Installing..."
  gem install bundler
fi

bundle install
