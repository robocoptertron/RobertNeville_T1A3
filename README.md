# CLIMate - a weather app

**CLIMate** is a command line weather forecasting application that I created as
the third assessment piece for my CoderAcademy studies. It enables its
users to search for any valid location around the globe by place name,
and can then be used to fetch current or weekly forecast data for
that place - based on the place's latitude and longitude.

## APIs Used

This app has made use of the following free APIs^:

- WorldTimeAPI : [http://worldtimeapi.org](http://worldtimeapi.org)
- Nominatim : [https://nominatim.org](https://nominatim.org)
- Open-Meteo : [https://open-meteo.com](https://open-meteo.com)

^*None of these APIs require a key*.

**WorldTimeAPI** has been used for determining the users' timezone when
running the application.

**Nomination** has been used for fetching geolocation data by place name.

**Open-Meteo** has been used for fetching current and weekly weather forecast
data for a given latitude and longitude.


## Source Control Repository

The code for this project can be found at 
[https://github.com/robocoptertron/RobertNeville_T1A3](https://github.com/robocoptertron/RobertNeville_T1A3).

## Coding Style Guide

This project has been written with the Airbnb Ruby Style Guide in mind.
In some cases, the maximum line length of 100 characters has been voilated 
by less than 10% to facilitate readability.

The Airbnb Ruby Style Guide can be found at 
[https://github.com/airbnb/ruby](https://github.com/airbnb/ruby).

## Application Features

CLIMate combines the following high-level features into a cohesive weather
forecasting service:

1. It integrates place name search functionality, enabling users to choose
from a list of places found to match their query.
2. Users can view current weather conditions for their chosen place name.
3. Users can view weekly weather forecasts for their chosen place name.
4. Users can save current or weekly weather data in their history for
later reference (perusable by starting the app with it's `--history`
command line option).
5. A user's current location can be cached to 'user locations' for 
convenience and faster app performance.
6. Arbitraty locations can be saved to the user's 'favourites' for 
convenience and faster app performance.
7. It offers a PDF export option for weekly weather forecasts (the user's
exports directory can be easily configured during app setup, or via use
of the `--config` command line option).

These features have been implemented with comprehensive use of Ruby
programming constructs.

## Implementation Plan

### Overview

CLIMate will be implemented with an object oriented approach. The primary 
application logic will be contained in an `App` class, and a `ConfigManager`
class will be created to handle the app's configuration. These two
classes will be instantiated in the app's entry point `main.rb`, wherein
initial command line argument processing will also take place. 

The constructor
for `App` will take a `ConfigManager` object as its only argument, and
will include an `exec` function to initiate the program's primary logic.
This function will operate on the command line arguments passed to the 
program, and will determine weather the user will interact with the
main CLIMate loop or the history or config subsystems.

A Bash script will be written to handle application setup - to install
all dependencies, create the configuration directory, 
and launch the app if the user so desires. The configuration directory
will contain the following four JSON configuration files, which will
be initialised with default content by the setup script:

1. `config.json`
2. `locations.json`
3. `favourites.json`
4. `history.json`

These files will store the app's general configuration, the user's
saved and favourite locations, and their forecast history, respectively.

The user will also have the option to specify the directory to be used for
PDF exports when following the setup procedure (this can also be changed
after setup by launching the app with the `--config` option and 
the `set` argument).

All API related methods will be implemented in separate modules - each 
pertaining to the one API.

### ArgumentParser

Prior to the commencement of this project, I was working on re-writing
a command line argument parser class, that I had partially implemented in
C++. I thought I might be able to use it in this project.

I discovered a Ruby gem available called `optparse` that can be used to parse
command line arguments. However, after experimentation with the package,
I decided that I would finish the custom argument parser that I was developing; 
`optparse` was not well documented and awkward to use.

CLIMate will include the custom '`ArgumentParser`' class.

### Flowcharts for `App` class `main_loop` method

#### main_loop method
![main_loop method flowchart](./docs/main-loop-flowchart.png)

#### 'get location' subprocess
![get location process flowchart](./docs/get-location-flowchart.png)

#### 'get weather' subprocess
![get weather process flowchart](./docs/get-weather-flowchart.png)

#### 'display forecast' subprocess
![display forecast process flowchart](./docs/print-weather-flowchart.png)