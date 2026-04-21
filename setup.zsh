#!/usr/bin/env zsh
set -e

RUBY_FORMULA="ruby@3.3"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it first: https://brew.sh"
  exit 1
fi

if ! brew list "$RUBY_FORMULA" >/dev/null 2>&1; then
  echo "Installing $RUBY_FORMULA via Homebrew..."
  brew install "$RUBY_FORMULA"
fi

RUBY_PREFIX="$(brew --prefix $RUBY_FORMULA)"
export PATH="$RUBY_PREFIX/bin:$PATH"

GEM_BIN="$(ruby -e 'puts Gem.bindir')"
export PATH="$GEM_BIN:$PATH"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools required. Run: xcode-select --install"
  exit 1
fi
export SDKROOT="$(xcrun --show-sdk-path)"

if ! command -v bundle >/dev/null 2>&1; then
  echo "Installing Bundler..."
  gem install bundler
fi

bundle config set --local path 'vendor/bundle'
bundle config set --local build.eventmachine \
  "--with-cppflags=-I$SDKROOT/usr/include/c++/v1 --with-cflags=-isysroot$SDKROOT"
bundle install
