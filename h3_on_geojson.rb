# This script is used to find all H3 hex ids inside a given geojson.

require 'json'
require 'csv'
require 'h3' # gem install h3

# CONFIGURATION

h3_resolution = 12
geojson_file_path = 'geojson.json'
output_geojson_file_path = 'geojson_h3_hexes.json'
output_table_file_path = 'table_h3_hexes.csv'

# END CONFIGURATION

# Read geojson file
puts "Reading geojson file: #{geojson_file_path}"
geojson = File.read(geojson_file_path)
geojson = JSON.parse(geojson)

# Load hexes
puts "Loading H3 hexes"
hexes = []
features = geojson['features']
features.each_with_index do |feature, index|
  puts "Processing feature: #{index + 1}/#{features.size}"
  case feature['geometry']['type']
  when 'Polygon'
    # Get all H3 hexes inside the Polygon
    hexes_on_polygon = H3.polyfill(feature['geometry'].to_json, h3_resolution)

    # Add hexes to the feature
    hexes << hexes_on_polygon
  when 'MultiPolygon'
    feature['geometry']['coordinates'].each do |polygon|
      polygon_geojson = {
        type: 'Polygon',
        coordinates: polygon
      }

      # Get all H3 hexes inside the Polygon
      hexes_on_polygon = H3.polyfill(polygon_geojson.to_json, h3_resolution)

      # Add hexes to the feature
      hexes << hexes_on_polygon
    end
  else
    raise "Geometry type not supported: #{feature['geometry']['type']}"
  end
end

# Create new geojson with hexes
puts "Creating new geojson with H3 hexes"
geojson_h3_hexes = {
  type: 'FeatureCollection',
  features: []
}
hexes = hexes.flatten.uniq
hexes.each do |hex|
  geojson_h3_hexes[:features] << {
    type: 'Feature',
    properties: {
      h3_hex_id: hex
    },
    geometry: {
      type: 'Polygon',
      coordinates: [H3.to_boundary(hex).map { |coord| [coord[1], coord[0]] }]
    }
  }
end

# Delete output file if it exists
puts "Deleting output file if it exists: #{output_geojson_file_path}"
File.delete(output_geojson_file_path) if File.exist?(output_geojson_file_path)

# Write geojson with hexes to file
puts "Writing geojson with H3 hexes to file: #{output_geojson_file_path}"
File.open(output_geojson_file_path, 'w') do |f|
  f.write(JSON.pretty_generate(geojson_h3_hexes))
end

# Delete output file if it exists
puts "Deleting output file if it exists: #{output_table_file_path}"
File.delete(output_table_file_path) if File.exist?(output_table_file_path)

# Create table with hexes
puts "Creating new CSV with H3 hexes"
CSV.open(output_table_file_path, 'wb') do |csv|
  csv << ['h3_hex_id']
  hexes.each do |hex|
    csv << [hex.to_s(16)]
  end
end

puts "Done!"
