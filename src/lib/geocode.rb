require "http"

module Geocode
  API_URL = "https://nominatim.openstreetmap.org/search?"
  FORMAT = "format=json"

  def self.search_places_by_name(name)
    q = "q=#{name}"
    response = nil
    begin
      response = HTTP.get("#{API_URL}#{q}&#{FORMAT}")
    rescue HTTP::ConnectionError
      {error: true}
    else
      data = response.parse
      places_found = []
      data.each do |place_found|
        places_found.push({
          "display_name" => place_found["display_name"],
          "latitude" => place_found["lat"],
          "longitude" => place_found["lon"]
        })
      end
      {error: false, places_found: places_found}
    end
  end
end