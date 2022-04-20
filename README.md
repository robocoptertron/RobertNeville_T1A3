# CLIMate - a weather app

**CLIMate** is a command line weather forecasting application that I created as
the third assessment piece for my CoderAcademy studies. It enables its
users to search for any valid location around the globe by place name,
and can then be used to fetch current or weekly forecast data for
that place - based on the place's latitude and longitude.

## APIs Used

This app has made use of the following free APIs:

- WorldTimeAPI : [http://worldtimeapi.org](http://worldtimeapi.org)
- Nominatim : [https://nominatim.org](https://nominatim.org)
- Open-Meteo : [https://open-meteo.com](https://open-meteo.com)

**WorldTimeAPI** has been used for determining the users' timezone when
running the application.

**Nomination** has been used for fetching geolocation data by place name.

**Open-Meteo** has been used for fetching current and weekly weather forecast
data for a given latitude and longitude.

