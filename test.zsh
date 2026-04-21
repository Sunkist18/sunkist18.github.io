#!/usr/bin/env zsh
set -e

RUBY_PREFIX="$(brew --prefix ruby@3.3)"
export PATH="$RUBY_PREFIX/bin:$PATH"
export PATH="$(ruby -e 'puts Gem.bindir'):$PATH"

bundle exec jekyll serve
