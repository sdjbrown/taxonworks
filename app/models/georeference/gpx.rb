# A Georeference derived from a GPX JSON object.
#
class Georeference::GPX < Georeference

  def initialize(request_params)
    super

  end

  # coordinates is an Array of Stings of [longitude, latitude]
  # @param [Symbol] geo_type
  # @param [Ignored] shape
  def make_geographic_item(geo_type, shape)
    case geo_type
      when :line_string
      when :point
    end
    self.geographic_item = GeographicItem.new(point: Gis::FACTORY.point(coordinates[0], coordinates[1]))
  end

  def dwc_georeference_attributes
    h = { 
      footprintWKT: geographic_item.geo_object.to_s,

      georeferenceSources: 'GPX data stored in image.',
      georeferenceRemarks: 'Auto-generated by dropping a image with coodrinates into a TaxonWorks interface.',
      georeferenceProtocol: 'Ex GPX data stored in image.',
      georeferenceVerificationStatus: confidences&.collect{|c| c.name}.join('; '), 
      georeferencedBy: creator.name,
      georeferencedDate: created_at
    }

    if geographic_item.type == 'GeographicItem::Point' 
      h[:decimalLatitude] = geographic_item.to_a.first
      h[:decimalLongitude] = geographic_item.to_a.last
      h[:coordinateUncertaintyInMeters] = error_radius 
    end

    h
  end 
 
end
