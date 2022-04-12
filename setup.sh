#!/bin/bash

# Paths used in this script:
CONFIG_DIR="$HOME/.CLIMate"
CONFIG_FILE="$CONFIG_DIR/config.json"
USER_LOCATIONS_FILE="$CONFIG_DIR/locations.json"
FAVOURITES_FILE="$CONFIG_DIR/favourites.json"
HISTORY_FILE="$CONFIG_DIR/history.json"
DEFAULT_EXPORTS_DIR="$HOME/Documents/CLIMate"

# Functions for initialising config files:

init_config_file() {
  touch $CONFIG_FILE
  cat > $CONFIG_FILE <<JSON
{ "output": "$1" }
JSON
}

init_user_locations_file() {
  touch $USER_LOCATIONS_FILE
  cat > $USER_LOCATIONS_FILE <<JSON
{ "locations": [] }
JSON
}

init_favourites_file() {
  touch $FAVOURITES_FILE
  cat > $FAVOURITES_FILE <<JSON
{ "favourites": [] }
JSON
}

init_history_file() {
  touch $HISTORY_FILE
  cat > $HISTORY_FILE <<JSON
[]
JSON
}

# Function to get user confirmation:
get_confirmation() {
  proceed=false
  while true; do
    read -p "$1" answer
    case $answer in
      y | Y) proceed=true; break;;
      n | N) break;;
      *) echo "Please enter 'y' or 'n'."
    esac
  done
  echo $proceed
}

# Check installed Ruby version:
version=$(ruby -v | grep -Po "[0-9]+\.[0-9]+\.[0-9]+")

# Install bundler and app dependencies:
gem install bundler
bundle install

# Setup config directory
if [[ ! -e $CONFIG_DIR ]]; then
  echo "Creating config directory: $CONFIG_DIR..."
  mkdir $CONFIG_DIR
fi

echo "Initialising config files in $CONFIG_DIR..."

init_user_locations_file
init_favourites_file
init_history_file

echo "CLIMate reports will be exported to $DEFAULT_EXPORTS_DIR by default."

change_default_export_dir=$(get_confirmation "Would you like to change this? (y/n) ")

if [[ $change_default_export_dir == false && ! -e $DEFAULT_EXPORTS_DIR ]]; then
  echo "Creating default exports directory: $DEFAULT_EXPORTS_DIR..."
  init_config_file $DEFAULT_EXPORTS_DIR
  mkdir $DEFAULT_EXPORTS_DIR
elif [[ $change_default_export_dir == false ]]; then
  echo "$DEFAULT_EXPORTS_DIR already exists. Skipping..."
else
  while true; do
    read -p "Where would you like them to be exported? " user_specified_exports_location
    if [[ ! -e $user_specified_exports_location ]]; then
      echo "The location you entered does not exist..."
      create_dir=$(get_confirmation "Would you like CLIMate to create it? (y/n) ")
      if [[ $create_dir == true ]]; then
        mkdir -p $user_specified_exports_location
        break
      else
        echo "Please try again."
      fi
    elif [[ ! -d $user_specified_exports_location ]]; then
      echo "The location you entered is not a directory."
      echo "Please try again."
    else
      init_config_file $user_specified_exports_location
    fi
  done
fi

echo "All set up!"

launch_app=$(get_confirmation "Would you like to launch climate now? (y/n) ")
if [[ $launch_app == true ]]; then 
  ruby ./src/main.rb
else
  echo "No worries. You can launch it when you're ready with the following command: ruby ./src/main.rb"
fi