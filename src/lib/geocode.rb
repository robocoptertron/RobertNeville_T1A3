require "http"

module Geocode
  API_URL = "https://nominatim.openstreetmap.org/search?"
  FORMAT = "format=json"
  
  def Geocode.search_places_by_name(name)
    q = "q=#{name}"
    response = nil
    begin
      response = HTTP.get("#{API_URL}#{q}&#{FORMAT}")
    rescue HTTP::ConnectionError
      message = "Oops - there was a connection error. Make sure you're connected to the internet."
      {"error" => message}
    else
      # The fetch operation completed:
      if response.status.server_error?
        # The request was received but there
        # was a server error:
        {"error" => "Oops - there was a server error. You might have to try again later."}
      end
      # Parse and process the data into
      # a format that is easier to work with:
      data = response.parse
      places_found = []
      data.each do |place_found|
        places_found.push({
          "osm_id" => place_found["osm_id"],
          "display_name" => place_found["display_name"],
          "latitude" => place_found["lat"],
          "longitude" => place_found["lon"]
        })
      end
      # Return the data:
      {"places_found" => places_found}
    end
  end
end