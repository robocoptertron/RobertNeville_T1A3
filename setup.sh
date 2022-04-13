#!/bin/bash

TESTED_RUBY_VERSION=3

# Paths used in this script:
CONFIG_DIR="$HOME/.CLIMate"
GENERAL_CONFIG_FILE="$CONFIG_DIR/config.json"
USER_LOCATIONS_FILE="$CONFIG_DIR/locations.json"
FAVOURITES_FILE="$CONFIG_DIR/favourites.json"
HISTORY_FILE="$CONFIG_DIR/history.json"
DEFAULT_EXPORTS_DIR="$HOME/Documents/CLIMate"

# Functions for initialising config files:

init_general_config_file() {
  touch $GENERAL_CONFIG_FILE
  cat > $GENERAL_CONFIG_FILE <<JSON
{ "output": "$1" }
JSON
}

init_user_locations_file() {
  echo "Creating $USER_LOCATIONS_FILE..."
  touch $USER_LOCATIONS_FILE
  cat > $USER_LOCATIONS_FILE <<JSON
{ "locations": [] }
JSON
}

init_favourites_file() {
  echo "Creating $FAVOURITES_FILE..."
  touch $FAVOURITES_FILE
  cat > $FAVOURITES_FILE <<JSON
{ "favourites": [] }
JSON
}

init_history_file() {
  echo "Creating $HISTORY_FILE..."
  touch $HISTORY_FILE
  cat > $HISTORY_FILE <<JSON
[]
JSON
}

# Creates config files if they do
# not already exist:
populate_config_dir() {
  if [[ ! -e $USER_LOCATIONS_FILE ]]; then
    init_user_locations_file
  fi

  if [[ ! -e $FAVOURITES_FILE ]]; then
    init_favourites_file
  fi

  if [[ ! -e $HISTORY_FILE ]]; then
    init_history_file
  fi
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
full_version=$(ruby -v | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
OLD_IFS="$IFS" 
IFS="."
read -a version_components <<< "$full_version"
major_version="${version_components[0]}"

if [[ major_version -lt TESTED_RUBY_VERSION ]]; then
  echo "WARNING"
  echo "A version of Ruby less than $TESTED_RUBY_VERSION" 
  echo "has been detected."
  echo "CLIMate has only been tested with Ruby 3.0.3, and"
  echo "some of the functionality may not be compatible"
  echo "with the version installed on this machine ($full_version)."
  echo 
  read -p "Hit ENTER to continue setup, or CTRL+C to abort"
  echo
fi

IFS="$OLD_IFS"

# Install bundler and app dependencies:
echo "Installing app dependencies..."
gem install bundler
bundle install
echo

# Setup config directory
if [[ ! -e $CONFIG_DIR ]]; then
  echo "Creating config directory: $CONFIG_DIR..."
  mkdir $CONFIG_DIR  
fi

populate_config_dir
echo

echo "CLIMate reports are exported to $DEFAULT_EXPORTS_DIR by default."

change_default_export_dir=$(get_confirmation "Would you like to change this? (y/n) ")

if [[ $change_default_export_dir == false && ! -e $DEFAULT_EXPORTS_DIR ]]; then
  # The user wants to keep the default exports directory.
  # It does not exist, so create it and initialise config.json
  # with this directory:
  echo "Creating default exports directory: $DEFAULT_EXPORTS_DIR..."
  init_general_config_file $DEFAULT_EXPORTS_DIR
  mkdir $DEFAULT_EXPORTS_DIR
elif [[ $change_default_export_dir == false ]]; then
  # The user wants to keep the default exports dir.
  # It already exists:
  init_general_config_file $DEFAULT_EXPORTS_DIR
  break
else
  # The user wants to specify their own exports directory
  while true; do
    read -p "Where would you like them to be exported? " user_specified_exports_location
    if [[ ! -e $user_specified_exports_location ]]; then
      # The location the user entered does not exist.
      # Confirm creation of the directory:
      echo "The location you entered does not exist..."
      create_dir=$(get_confirmation "Would you like CLIMate to create it? (y/n) ")
      if [[ $create_dir == true ]]; then
        # Create the directory and init config file with
        # that directory for exports:
        mkdir $user_specified_exports_location
        init_general_config_file $user_specified_exports_location
        break
      else
        echo "Please try again."
      fi
    elif [[ ! -d $user_specified_exports_location ]]; then
      # The user entered a path the represents 
      # a non-directory file-system object:
      echo "The location you entered is not a directory."
      echo "Please try again."
    else
      # The user entered a valid directory. Init config
      # file with that directory for exports:
      init_general_config_file $user_specified_exports_location
      break
    fi
  done
fi

echo "All set up!"

launch_app=$(get_confirmation "Would you like to launch CLIMate now? (y/n) ")
if [[ $launch_app == true ]]; then 
  ruby ./src/main.rb
else
  echo "No worries. You can launch it when you're ready with the following command: ruby ./src/main.rb"
fi