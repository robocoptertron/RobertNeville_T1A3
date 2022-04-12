#!/bin/bash

CONFIG_DIR="$HOME/.CLIMate"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Install bundler and app dependencies
gem install bundler
bundle install

# Setup config directory

if [[ ! -e $CONFIG_DIR ]]; then
  echo "Creating config directory: $CONFIG_DIR..."
  mkdir $CONFIG_DIR
fi

if [[ ! -e $CONFIG_FILE ]]; then
  echo "Creating config file for application: $CONFIG_FILE..."
  touch $CONFIG_FILE
fi

exit