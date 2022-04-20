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
later reference.
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

CLIMate has been designed with an object oriented application architecture.