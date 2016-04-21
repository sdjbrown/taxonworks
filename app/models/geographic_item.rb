require 'rgeo'

# A GeographicItem is one and only one of [point, line_string, polygon, multi_point, multi_line_string,
# multi_polygon, geometry_collection] which describes a position, path, or area on the globe, generally associated
# with a geographic_area (through a geographic_area_geographic_item entry), and sometimes only with a georeference.
#
# @!attribute point
#   @return [RGeo::Geographic::ProjectedPointImpl]
#
# @!attribute line_string
#   @return [RGeo::Geographic::ProjectedLineStringImpl]
#
# @!attribute polygon
#   @return [RGeo::Geographic::ProjectedPolygonImpl]
#
# @!attribute multi_point
#   @return [RGeo::Geographic::ProjectedMultiPointImpl]
#
# @!attribute multi_line_string
#   @return [RGeo::Geographic::ProjectedMultiLineStringImpl]
#
# @!attribute multi_polygon
#   @return [RGeo::Geographic::ProjectedMultiPolygonImpl]
#
# @!attribute type
#   @return [String]
#     Rails STI, determines the geography column as well
#
class GeographicItem < ActiveRecord::Base
  include Housekeeping::Users
  include Housekeeping::Timestamps
  include Shared::IsData
  include Shared::SharedAcrossProjects

  # an internal variable for use in super calls, holds a geo_json hash (temporarily)
  attr_accessor :geometry

  attr_accessor :shape

  DATA_TYPES = [:point,
                :line_string,
                :polygon,
                :multi_point,
                :multi_line_string,
                :multi_polygon,
                :geometry_collection].freeze

  GEOMETRY_SQL = "CASE geographic_items.type
         WHEN 'GeographicItem::MultiPolygon' THEN multi_polygon::geometry
         WHEN 'GeographicItem::Point' THEN point::geometry
         WHEN 'GeographicItem::LineString' THEN line_string::geometry
         WHEN 'GeographicItem::Polygon' THEN polygon::geometry
         WHEN 'GeographicItem::MultiLineString' THEN multi_line_string::geometry
         WHEN 'GeographicItem::MultiPoint' THEN multi_point::geometry
         WHEN 'GeographicItem::GeometryCollection' THEN geometry_collection::geometry
      END".freeze

  GEOGRAPHY_SQL = "CASE geographic_items.type
     WHEN 'GeographicItem::MultiPolygon' THEN multi_polygon
     WHEN 'GeographicItem::Point' THEN point
     WHEN 'GeographicItem::LineString' THEN line_string
     WHEN 'GeographicItem::Polygon' THEN polygon
     WHEN 'GeographicItem::MultiLineString' THEN multi_line_string
     WHEN 'GeographicItem::MultiPoint' THEN multi_point
     WHEN 'GeographicItem::GeometryCollection' THEN geometry_collection
  END".freeze

  has_many :geographic_areas_geographic_items, dependent: :destroy, inverse_of: :geographic_item
  has_many :geographic_areas, through: :geographic_areas_geographic_items
  has_many :geographic_area_types, through: :geographic_areas
  has_many :parent_geographic_areas, through: :geographic_areas, source: :parent
  has_many :gadm_geographic_areas, class_name: 'GeographicArea', foreign_key: :gadm_geo_item_id
  has_many :ne_geographic_areas, class_name: 'GeographicArea', foreign_key: :ne_geo_item_id
  has_many :tdwg_geographic_areas, class_name: 'GeographicArea', foreign_key: :tdwg_geo_item_id
  has_many :georeferences
  has_many :georeferences_through_error_geographic_item, class_name: 'Georeference', foreign_key: :error_geographic_item_id
  has_many :collecting_events_through_georeferences, through: :georeferences, source: :collecting_event
  has_many :collecting_events_through_georeference_error_geographic_item, through: :georeferences_through_error_geographic_item, source: :collecting_event

  before_validation :set_type_if_geography_present

  validate :some_data_is_provided
  validates :type, presence: true

  scope :include_collecting_event, -> { includes(:collecting_events_through_georeferences) }
  scope :geo_with_collecting_event, -> { joins(:collecting_events_through_georeferences) }
  scope :err_with_collecting_event, -> { joins(:georeferences_through_error_geographic_item) }

  class << self

    #
    # SQL fragments
    #

    # @param [Integer, String]
    # @return [String]
    #   a SQL select statement that returns the *geometry* for the geographic_item with the specified id
    def select_geometry_sql(geographic_item_id)
      "SELECT #{GeographicItem::GEOMETRY_SQL} from geographic_items where geographic_items.id = #{geographic_item_id}"
    end

    # @param [Integer, String]
    # @return [String]
    #   a SQL select statement that returns the geography for the geographic_item with the specified id
    def select_geography_sql(geographic_item_id)
      "SELECT #{GeographicItem::GEOMETRY_SQL} from geographic_items where geographic_items.id = #{geographic_item_id}"
    end
    
    # @return [String] 
    #   a fragment returning either latitude or longitude columns
    def lat_long_sql(choice)
      return nil unless [:latitude, :longitude].include?(choice)
      f = "'D.DDDDDD'" # TODO: probably a constant somewhere
      v = (choice == :latitude ? 1 : 2)
      "CASE type
        WHEN 'GeographicItem::GeometryCollection' THEN split_part(ST_AsLatLonText(ST_Centroid(geometry_collection::geometry), #{f}), ' ', #{v})
        WHEN 'GeographicItem::LineString' THEN split_part(ST_AsLatLonText(ST_Centroid(line_string::geometry), #{f}), ' ', #{v})
        WHEN 'GeographicItem::MultiPolygon' THEN split_part(ST_AsLatLonText(ST_Centroid(multi_polygon::geometry), #{f}), ' ', #{v})
        WHEN 'GeographicItem::Point' THEN split_part(ST_AsLatLonText(ST_Centroid(point::geometry), #{f}), ' ', #{v})
        WHEN 'GeographicItem::Polygon' THEN split_part(ST_AsLatLonText(ST_Centroid(polygon::geometry), #{f}), ' ', #{v})
        WHEN 'GeographicItem::MultiLineString' THEN split_part(ST_AsLatLonText(ST_Centroid(multi_line_string::geometry), #{f} ), ' ', #{v})
        WHEN 'GeographicItem::MultiPoint' THEN split_part(ST_AsLatLonText(ST_Centroid(multi_point::geometry), #{f}), ' ', #{v})
      END as #{choice}"
    end

    # @return [String]
    def within_radius_of_item_sql(geographic_item_id, distance)
      "ST_DWithin((#{GeographicItem::GEOGRAPHY_SQL}), (#{select_geography_sql(geographic_item_id)}), #{distance})"
    end

    # @return [String] 
    def within_radius_of_wkt_sql(wkt, distance)
      "ST_DWithin((#{GeographicItem::GEOGRAPHY_SQL}), ST_Transform( ST_GeomFromText('#{wkt}', 4326), 4326), #{distance})"
    end

    # @param [String, Integer, String]
    # @return [String]
    #   a SQL fragment for ST_Contains() function, returns
    #   all geographic items which are contained in the item supplied
    def containing_sql(target_column_name = nil, geographic_item_id = nil, source_column_name = nil)
      return 'false' if geographic_item_id.nil? || source_column_name.nil? || target_column_name.nil?
      "ST_Contains(#{target_column_name}::geometry, (#{geometry_sql(geographic_item_id, source_column_name)}))"
    end

    # @param [String, Integer, String]
    # @return [String]
    #   a SQL fragment for ST_Contains(), returns
    #   all geographic_items which contain the supplied geographic_item
    def reverse_containing_sql(target_column_name = nil, geographic_item_id = nil, source_column_name = nil)
      return 'false' if geographic_item_id.nil? || source_column_name.nil? || target_column_name.nil?
      "ST_Contains((#{geometry_sql(geographic_item_id, source_column_name)}), #{target_column_name}::geometry)"
    end

    # @param [Integer, String]
    # @return [String]
    #   a SQL fragment that represents the geometry of the geographic item specified (which has data in the source_column_name, i.e. geo_object_type)
    def geometry_sql(geographic_item_id = nil, source_column_name = nil)
      return 'false' if geographic_item_id.nil? || source_column_name.nil?
      "select geom_alias_tbl.#{source_column_name}::geometry from geographic_items geom_alias_tbl where geom_alias_tbl.id = #{geographic_item_id}"
    end

    def is_contained_by_sql(column_name, geographic_item)
      geo_id   = geographic_item.id
      geo_type = geographic_item.geo_object_type
      template = '(ST_Contains((select geographic_items.%s::geometry from geographic_items where geographic_items.id = %d), %s::geometry))'
      retval   = []
      column_name.downcase!
      case column_name
      when 'any'
        DATA_TYPES.each { |column|
          unless column == :geometry_collection
            retval.push(template % [geo_type, geo_id, column])
          end
        }
      when 'any_poly', 'any_line'
        DATA_TYPES.each { |column|
          unless column == :geometry_collection
            if column.to_s.index(column_name.gsub('any_', ''))
              retval.push(template % [geo_type, geo_id, column])
            end
          end
        }
      else
        retval = template % [geo_type, geo_id, column_name]
      end
      retval = retval.join(' OR ') if retval.instance_of?(Array)
      retval
    end

    # @return [String]
    #   a select query that returns a single geometery (column name 'single_geometry' for the collection of ids provided via ST_Collect)
    def st_collect_sql(*geographic_item_ids)
      "SELECT ST_Collect(f.the_geom) AS single_geometry
       FROM (
          SELECT (ST_DUMP(#{GeographicItem::GEOMETRY_SQL})).geom as the_geom
          FROM geographic_items
          WHERE id in (#{geographic_item_ids.join(',')}))
        AS f"
    end

    def single_geometry_sql(*geographic_item_ids)
      "(SELECT single.single_geometry FROM (#{GeographicItem.st_collect_sql(geographic_item_ids)}) AS single)"
    end

    # @return [String]
    #   returns a single geometery "column" (paren wrapped) as "single" for multiple geographic item ids, or the geometry as 'geometry' for a single id
    def geometry_sql2(*geographic_item_ids)
      if geographic_item_ids.count == 1
        "(#{GeographicItem.geometry_for_sql(geographic_item_ids.flatten.first)})"
      else
        GeographicItem.single_geometry_sql(geographic_item_ids)
      end
    end

    def containing_where_sql(*geographic_item_ids)
      "ST_CoveredBy(
      #{GeographicItem.geometry_sql2(*geographic_item_ids)},
       CASE geographic_items.type
         WHEN 'GeographicItem::MultiPolygon' THEN multi_polygon::geometry
         WHEN 'GeographicItem::Point' THEN point::geometry
         WHEN 'GeographicItem::LineString' THEN line_string::geometry
         WHEN 'GeographicItem::Polygon' THEN polygon::geometry
         WHEN 'GeographicItem::MultiLineString' THEN multi_line_string::geometry
         WHEN 'GeographicItem::MultiPoint' THEN multi_point::geometry
      END)"     
    end

    # TODO: Remove the hard coded 4326 reference
    def contained_by_wkt_sql(wkt)
      "ST_ContainsProperly(ST_GeomFromText('#{wkt}', 4326), (
        CASE geographic_items.type
           WHEN 'GeographicItem::MultiPolygon' THEN multi_polygon::geometry
           WHEN 'GeographicItem::Point' THEN point::geometry
           WHEN 'GeographicItem::LineString' THEN line_string::geometry
           WHEN 'GeographicItem::Polygon' THEN polygon::geometry
           WHEN 'GeographicItem::MultiLineString' THEN multi_line_string::geometry
           WHEN 'GeographicItem::MultiPoint' THEN multi_point::geometry
        END
        ) 
      )"
    end

    # @return [String] sql for contained_by via ST_ContainsProperly
    # Note: Can not use GEOMETRY_SQL because geometry_collection is not supported in ST_ContainsProperly
    def contained_by_where_sql(*geographic_item_ids)
      "ST_ContainsProperly(
      #{GeographicItem.geometry_sql2(*geographic_item_ids)},
      CASE geographic_items.type
         WHEN 'GeographicItem::MultiPolygon' THEN multi_polygon::geometry
         WHEN 'GeographicItem::Point' THEN point::geometry
         WHEN 'GeographicItem::LineString' THEN line_string::geometry
         WHEN 'GeographicItem::Polygon' THEN polygon::geometry
         WHEN 'GeographicItem::MultiLineString' THEN multi_line_string::geometry
         WHEN 'GeographicItem::MultiPoint' THEN multi_point::geometry
      END)"
    end

    # @return [String] sql for containing via ST_CoveredBy
    # TODO: Remove the hard coded 4326 reference
    # TODO: should this be wkt_point instaead of rgeo_point?
    def containing_where_for_point_sql(rgeo_point)
      "ST_CoveredBy(
        ST_GeomFromText('#{rgeo_point}', 4326),
        #{GeographicItem::GEOMETRY_SQL}
       )"
    end

    # example, not used
    def geometry_for_sql(geographic_item_id)
      'SELECT ' + GeographicItem::GEOMETRY_SQL + " AS geometry FROM geographic_items WHERE id = #{geographic_item_id} LIMIT 1"
    end

    # example, not used
    def geometry_for_collection_sql(*geographic_item_ids)
      'SELECT ' + GeographicItem::GEOMETRY_SQL + " AS geometry FROM geographic_items wHERE id IN ( #{geographic_item_ids.join(',')} )"
    end

    # 
    # Scopes
    #

    # @return [Scope]
    #    the geographic items containing these collective geographic_item ids, not including self
    def containing(*geographic_item_ids)
      where(GeographicItem.containing_where_sql(geographic_item_ids)).not_ids(*geographic_item_ids)
    end

    # @return [Scope]
    #    the geographic items contained by any of these geographic_item ids, not including self (works via ST_ContainsProperly)
    def contained_by(*geographic_item_ids)
      where(GeographicItem.contained_by_where_sql(geographic_item_ids))
    end

    # @return [Scope]
    #    the geographic items containing this point
    # TODO: should be containing_wkt ?
    def containing_point(rgeo_point)
      where(GeographicItem.containing_where_for_point_sql(rgeo_point))
    end

    # @return [Scope]
    # @param [String] 'ASC' or 'DESC'
    def ordered_by_area(direction = 'ASC')
      order("ST_Area(#{GeographicItem::GEOMETRY_SQL}) #{direction}")
    end

    # @return [Scope]
    #   adds an area_in_meters field, with meters
    def with_area
      select("ST_Area(#{GeographicItem::GEOGRAPHY_SQL}, false) as area_in_meters")
    end

    # return [Scope]
    #   A scope that limits the result to those GeographicItems that have a collecting event
    #   through either the geographic_item or the error_geographic_item
    #
    # A raw SQL join approach for comparison
    #
    # GeographicItem.joins('LEFT JOIN georeferences g1 ON geographic_items.id = g1.geographic_item_id').
    #   joins('LEFT JOIN georeferences g2 ON geographic_items.id = g2.error_geographic_item_id').
    #   where("(g1.geographic_item_id IS NOT NULL OR g2.error_geographic_item_id IS NOT NULL)").uniq

    # @return [Scope] GeographicItem
    # This uses an Arel table approach, this is ultimately more decomposable if we need. Of use:
    #  http://danshultz.github.io/talks/mastering_activerecord_arel  <- best
    #  https://github.com/rails/arel
    #  http://stackoverflow.com/questions/4500629/use-arel-for-a-nested-set-join-query-and-convert-to-activerecordrelation
    #  http://rdoc.info/github/rails/arel/Arel/SelectManager
    #  http://stackoverflow.com/questions/7976358/activerecord-arel-or-condition
    #
    def with_collecting_event_through_georeferences
      geographic_items = GeographicItem.arel_table
      georeferences    = Georeference.arel_table
      g1               = georeferences.alias('a')
      g2               = georeferences.alias('b')

      c = geographic_items.join(g1, Arel::Nodes::OuterJoin).on(geographic_items[:id].eq(g1[:geographic_item_id]))
            .join(g2, Arel::Nodes::OuterJoin).on(geographic_items[:id].eq(g2[:error_geographic_item_id]))

      GeographicItem.joins(# turn the Arel back into scope
        c.join_sources # translate the Arel join to a join hash(?)
      ).where(
        g1[:id].not_eq(nil).or(g2[:id].not_eq(nil)) # returns a Arel::Nodes::Grouping
      ).distinct
    end

    # @return [Scope] include a 'latitude' column
    def with_latitude
      select(lat_long_sql(:latitude))
    end

    # @return [Scope] include a 'longitude' column
    def with_longitude
      select(lat_long_sql(:longitude))
    end

    # @param [String, GeographicItems]
    # @return [Scope]
    def intersecting(column_name, *geographic_items)
      if column_name.downcase == 'any'
        pieces = []
        DATA_TYPES.each { |column|
          pieces.push(GeographicItem.intersecting(column.to_s, geographic_items).to_a)
        }

        # @TODO change 'id in (?)' to some other sql construct

        GeographicItem.where(id: pieces.flatten.map(&:id))
      else
        q = geographic_items.flatten.collect { |geographic_item|
          "ST_Intersects(#{column_name}, '#{geographic_item.geo_object}'    )" # seems like we want this: http://danshultz.github.io/talks/mastering_activerecord_arel/#/15/2
        }.join(' or ')

        where(q)
      end
    end

    # @param [String] column_name
    # @param [GeographicItem#id] geographic_item_id
    # @param [Float] distance in meters
    # @return [ActiveRecord::Relation]
    # !! should be distance, not radius?!
    def within_radius_of_item(geographic_item_id, distance) 
      where( within_radius_of_item_sql(geographic_item_id, distance) )
    end

    # @param [String, GeographicItem]
    # @return [Scope]
    #   a SQL fragment for ST_DISJOINT, specifies all geographic_items that have data in column_name
    #   that are disjoint from the passed geographic_items
    def disjoint_from(column_name, *geographic_items)
      q = geographic_items.flatten.collect { |geographic_item|
        "ST_DISJOINT(#{column_name}::geometry, (#{geometry_sql(geographic_item.to_param, geographic_item.geo_object_type)}))"
      }.join(' and ')

      where(q)
    end

    # @return [Scope]
    #   see are_contained_in_item_by_id
    def are_contained_in_item(column_name, *geographic_items)
      are_contained_in_item_by_id(column_name, geographic_items.flatten.map(&:id))
    end

    # @param [String] column_name to search
    # @param [GeographicItem] geographic_item_id or array of geographic_item_ids to be tested.
    # @return [Scope] of GeographicItems
    #
    # If this scope is given an Array of GeographicItems as a second parameter,
    # it will return the 'OR' of each of the objects against the table.
    # SELECT COUNT(*) FROM "geographic_items"
    #        WHERE (ST_Contains(polygon::geometry, GeomFromEWKT('srid=4326;POINT (0.0 0.0 0.0)'))
    #               OR ST_Contains(polygon::geometry, GeomFromEWKT('srid=4326;POINT (-9.8 5.0 0.0)')))
    #
    def are_contained_in_item_by_id(column_name, *geographic_item_ids) # = containing
      geographic_item_ids.flatten! # in case there is a array of arrays, or multiple objects
      column_name.downcase!
      case column_name
        when 'any'
          part = []
          DATA_TYPES.each { |column|
            unless column == :geometry_collection
              part.push(GeographicItem.are_contained_in_item_by_id(column.to_s, geographic_item_ids).to_a)
            end
          }
          # TODO: change 'id in (?)' to some other sql construct
          GeographicItem.where(id: part.flatten.map(&:id))
        when 'any_poly', 'any_line'
          part = []
          DATA_TYPES.each { |column|
            if column.to_s.index(column_name.gsub('any_', ''))
              part.push(GeographicItem.are_contained_in_item_by_id("#{column}", geographic_item_ids).to_a)
            end
          }
          # TODO: change 'id in (?)' to some other sql construct
          GeographicItem.where(id: part.flatten.map(&:id))
        else
          q = geographic_item_ids.flatten.collect { |geographic_item_id|
            # discover the item types, and convert type to database type for 'multi_'
            b = GeographicItem.where(id: geographic_item_id).pluck(:type)[0].split(':')[2].downcase.gsub('lti', 'lti_')
            # a = GeographicItem.find(geographic_item_id).geo_object_type
            GeographicItem.containing_sql(column_name, geographic_item_id, b)
          }.join(' or ')
          q = 'FALSE' if q.blank? # this will prevent the invocation of *ALL* of the GeographicItems, if there are
          # no GeographicItems in the request (see CollectingEvent.name_hash(types)).
          where(q) # .excluding(geographic_items)
      end
    end

    # @param [String] column_name
    # @param [String] geometry of WKT
    # @return [Scope]
    # a single WKT geometry is compared against column or columns (except geometry_collection) to find geographic_items
    # which are contained in the WKT
    def are_contained_in_wkt(column_name, geometry)
      column_name.downcase!
      # column_name = 'point'
      case column_name
        when 'any'
          part = []
          DATA_TYPES.each { |column|
            unless column == :geometry_collection
              part.push(GeographicItem.are_contained_in_wkt(column.to_s, geometry).pluck(:id).to_a)
            end
          }
          # TODO: change 'id in (?)' to some other sql construct
          GeographicItem.where(id: part.flatten)
        when 'any_poly', 'any_line'
          part = []
          DATA_TYPES.each { |column|
            if column.to_s.index(column_name.gsub('any_', ''))
              part.push(GeographicItem.are_contained_in_wkt("#{column}", geometry).pluck(:id).to_a)
            end
          }
          # TODO: change 'id in (?)' to some other sql construct
          GeographicItem.where(id: part.flatten)
        else
          # column = points, geometry = square
          q = "ST_Contains(ST_GeomFromEWKT('srid=4326;#{geometry}'), #{column_name}::geometry)"
          where(q) # .excluding(geographic_items)
      end
    end

    # @return [Scope]
    #    containing the items the shape of which is contained in the geographic_item[s] supplied.
    # @param column_name [String] can be any of DATA_TYPES, or 'any' to check against all types, 'any_poly' to check
    # against 'polygon' or 'multi_polygon', or 'any_line' to check against 'line_string' or 'multi_line_string'.
    #  CANNOT be 'geometry_collection'.
    # @param geographic_items [GeographicItem] Can be a single GeographicItem, or an array of GeographicItem.
    def is_contained_by(column_name, *geographic_items)
      column_name.downcase!
      case column_name
        when 'any'
          part = []
          DATA_TYPES.each { |column|
            unless column == :geometry_collection
              part.push(GeographicItem.is_contained_by(column.to_s, geographic_items).to_a)
            end
          }
          # @TODO change 'id in (?)' to some other sql construct
          GeographicItem.where(id: part.flatten.map(&:id))

        when 'any_poly', 'any_line'
          part = []
          DATA_TYPES.each { |column|
            unless column == :geometry_collection
              if column.to_s.index(column_name.gsub('any_', ''))
                part.push(GeographicItem.is_contained_by(column.to_s, geographic_items).to_a)
              end
            end
          }
          # @TODO change 'id in (?)' to some other sql construct
          GeographicItem.where(id: part.flatten.map(&:id))

        else
          q = geographic_items.flatten.collect { |geographic_item|
            GeographicItem.reverse_containing_sql(column_name, geographic_item.to_param, geographic_item.geo_object_type)
          }.join(' or ')
          where(q) # .excluding(geographic_items)
      end
    end


    # @param [String, GeographicItem]
    # @return [Scope]
    def ordered_by_shortest_distance_from(column_name, geographic_item)
      if true # check_geo_params(column_name, geographic_item)
        select_distance_with_geo_object(column_name, geographic_item).where_distance_greater_than_zero(column_name, geographic_item).order('distance')
      else
        where('false')
      end
    end

    # @param [String, GeographicItem]
    # @return [Scope]
    def ordered_by_longest_distance_from(column_name, geographic_item)
      if true # check_geo_params(column_name, geographic_item)
        q = select_distance_with_geo_object(column_name, geographic_item)
              .where_distance_greater_than_zero(column_name, geographic_item)
              .order('distance desc')
        q
      else
        where('false')
      end
    end

    # @param [String, GeographicItem]
    # @return [String]
    def select_distance_with_geo_object(column_name, geographic_item)
      select("*, ST_Distance(#{column_name}, GeomFromEWKT('srid=4326;#{geographic_item.geo_object}')) as distance")
    end

    # @param [String, GeographicItem]
    # @return [Scope]
    def where_distance_greater_than_zero(column_name, geographic_item)
      where("#{column_name} is not null and ST_Distance(#{column_name}, GeomFromEWKT('srid=4326;#{geographic_item.geo_object}')) > 0")
    end

    # @param [GeographicItem]
    # @return [Scope]
    def excluding(geographic_items)
      where.not(id: geographic_items)
    end

    # @return [Scope]
    #   includes an 'is_valid' attribute (True/False) for the passed geographic_item.  Uses St_IsValid.
    def with_is_valid_geometry_column(geographic_item)
      where(id: geographic_item.id).select("ST_IsValid(ST_AsBinary(#{geographic_item.geo_object_type})) is_valid")
    end

    #
    # Other
    #

    def distance_between(geographic_item_id1, geographic_item_id2)
      GeographicItem.where(id: geographic_item_id1).pluck("st_distance(#{GeographicItem::GEOGRAPHY_SQL}, (#{select_geography_sql(geographic_item_id2)})) as distance").first
    end

    # @return [Hash]
    #   as per #inferred_geographic_name_hierarchy but for Rgeo point
    def point_inferred_geographic_name_hierarchy(point)
      GeographicItem.containing_point(point).ordered_by_area.limit(1).first.inferred_geographic_name_hierarchy
    end

    # @param [String] type_name ('polygon', 'point', 'line' [, 'circle'])
    # @return [String] if type
    def eval_for_type(type_name)
      retval = 'GeographicItem'
      case type_name.upcase
        when 'POLYGON'
          retval += '::Polygon'
        when 'LINESTRING'
          retval += '::LineString'
        when 'POINT'
          retval += '::Point'
        when 'MULTIPOLYGON'
          retval += '::MultiPolygon'
        when 'MULTILINESTRING'
          retval += '::MultiLineString'
        when 'MULTIPOINT'
          retval += '::MultiPoint'
        else
          retval = nil
      end
      retval
    end

    # example, not used
    def geometry_for(geographic_item_id)
      GeographicItem.select(GeographicItem::GEOMETRY_SQL + ' AS geometry').find(geographic_item_id)['geometry']
    end

    # example, not used
    def st_multi(*geographic_item_ids)
      GeographicItem.find_by_sql(
        "SELECT ST_Multi(ST_Collect(g.the_geom)) AS singlegeom
       FROM (
          SELECT (ST_DUMP(#{GeographicItem::GEOMETRY_SQL})).geom AS the_geom
          FROM geographic_items
          WHERE id IN (#{geographic_item_ids.join(',')}))
        AS g;"
      )
    end


  end # class << self

  # @return [Hash]
  #   a quick, geographic area hierarchy based approach to
  #   returning country, state, and county categories
  #   !! Note this just takes the first referenced GeographicArea, which should be safe most cases
  def quick_geographic_name_hierarchy
    v = {}
    a = geographic_areas.first.try(:geographic_name_classification)
    v = a unless a.nil?
    v
  end

  # @return [Hash]
  #   a slower, gis-based inference approach to
  #     returning country, state, and county categories
  def inferred_geographic_name_hierarchy
    v = {}
    (containing_geographic_areas + geographic_areas.limit(1)).each do |a|
      v.merge!(a.categorize)
    end
    v
  end

  # @return [Scope]
  #   the Geographic Areas that contain (gis) this geographic item
  def containing_geographic_areas
    GeographicArea.joins(:geographic_items).includes(:geographic_area_type)
      .joins("JOIN (#{GeographicItem.containing(id).to_sql}) j on geographic_items.id = j.id")
  end

  # @return [Boolean]
  #   whether stored shape is ST_IsValid
  def valid_geometry?
    GeographicItem.with_is_valid_geometry_column(self).first['is_valid']
  end

  # @return [Array of latitude, longitude]
  #    the lat, lon of the first point in the GeoItem, see subclass for #st_start_point
  def start_point
    o = st_start_point
    [o.y, o.x]
  end

  # @return [Array]
  #   the lat, long, as STRINGs for the centroid of this geographic item
  def center_coords
    r = GeographicItem.find_by_sql("Select split_part(ST_AsLatLonText(ST_Centroid(#{GeographicItem::GEOMETRY_SQL}), 'D.DDDDDD'), ' ', 1) latitude,
    split_part(ST_AsLatLonText(ST_Centroid(#{GeographicItem::GEOMETRY_SQL}), 'D.DDDDDD'), ' ', 2) longitude from geographic_items where id = #{id};")[0]

    [r.latitude, r.longitude]
  end

  # @return [Double] distance in meters (slower, more accurate)
  def st_distance(geographic_item_id) # geo_object
    GeographicItem.where(id: id).pluck("ST_Distance((#{GeographicItem.select_geography_sql(self.id)}), (#{GeographicItem.select_geography_sql(geographic_item_id)})) as d").first
  end

  alias_method :distance_to, :st_distance

  # @return [Double] distance in meters (faster, less accurate)
  def st_distance_spheroid(geographic_item_id) 
    GeographicItem.where(id: id).pluck("ST_Distance_Spheroid((#{GeographicItem.select_geometry_sql(self.id)}),(#{GeographicItem.select_geometry_sql(geographic_item_id)}),'#{Gis::SPHEROID}') as distance").first
  end

  # @return [String]
  #   a WKT POINT representing the centroid of the geographic item
  def st_centroid
    GeographicItem.where(id: to_param).pluck("ST_AsEWKT(ST_Centroid(#{GeographicItem::GEOMETRY_SQL}))").first.gsub(/SRID=\d*;/, '')
  end

  # @return [Integer]
  #   the number of points in the geometry
  def st_npoints
    GeographicItem.where(id: id).pluck("ST_NPoints(#{GeographicItem::GEOMETRY_SQL}) as npoints").first
  end

  # @return [Symbol]
  #   the geo type (i.e. column like :point, :multipolygon).  References the first-found object, according to the list of DATA_TYPES, or nil
  def geo_object_type
    if self.class.name == 'GeographicItem' # a proxy check for new records
      geo_type
    else
      self.class::SHAPE_COLUMN
    end
  end

  # !!TODO: migrate these to use native column calls this to "native" 

  # @return [RGeo instance, nil]
  #  the Rgeo shape (See http://rubydoc.info/github/dazuma/rgeo/RGeo/Feature)
  def geo_object
    if r = geo_object_type # rubocop:disable Lint/AssignmentInCondition
      send(r)
    else
      false
    end
  end

  # @param [geo_object]
  # @return [Boolean]
  def contains?(geo_object)
    self.geo_object.contains?(geo_object)
  end

  # @param [geo_object]
  # @return [Boolean]
  def within?(geo_object)
    self.geo_object.within?(geo_object)
  end

  # @TODO doesn't work?
  # @param [geo_object]
  # @return [Boolean]
  def distance?(geo_object)
    self.geo_object.distance?(geo_object)
  end

  # @param [geo_object, Double]
  # @return [Boolean]
  def near(geo_object, distance)
    self.geo_object.buffer(distance).contains?(geo_object)
  end

  # @param [geo_object, Double]
  # @return [Boolean]
  def far(geo_object, distance)
    !near(geo_object, distance)
  end

  # @return [GeoJSON hash]
  #    via Rgeo apparently necessary for GeometryCollection
  def rgeo_to_geo_json
    RGeo::GeoJSON.encode(geo_object).to_json
  end

  # @return [GeoJSON hash]
  #   raw Postgis (much faster)
  def to_geo_json
    JSON.parse(GeographicItem.connection.select_all("SELECT ST_AsGeoJSON(#{geo_object_type}::geometry) a FROM geographic_items WHERE id=#{id};").first['a'])
  end

  # @return [GeoJSON Feature] the shape as a GeoJSON Feature
  def to_geo_json_feature
    @geometry ||= to_geo_json
    {
      'type'       => 'Feature',
      'geometry'   => geometry,
      'properties' => {
        'geographic_item' => {
          'id' => id}
      }
    }
  end

  # '{"type":"Feature","geometry":{"type":"Point","coordinates":[2.5,4.0]},"properties":{"color":"red"}}'
  # '{"type":"Feature","geometry":{"type":"Polygon","coordinates":"[[[-125.29394388198853, 48.584480409793],
  # [-67.11035013198853, 45.09937589848195],[-80.64550638198853, 25.01924647619111],[-117.55956888198853,
  # 32.5591595028449],[-125.29394388198853, 48.584480409793]]]"},"properties":{}}'
  # @param [String] value
  def shape=(value)
    unless value.blank?
      geom      = RGeo::GeoJSON.decode(value, json_parser: :json)
      this_type = JSON.parse(value)['geometry']['type']

      # TODO: @tuckerjd isn't this set automatically? Or perhaps the callback isn't hit in this approach?
      self.type = GeographicItem.eval_for_type(this_type) unless geom.nil?
      raise('GeographicItem.type not set.') if type.blank?

      object = Gis::FACTORY.parse_wkt(geom.geometry.to_s)
      write_attribute(this_type.underscore.to_sym, object)
      geom
    end
  end

  protected

  # @return [Symbol]
  #   returns the attribute (column name) containing data
  #   nearly all methods should use #geo_object_type, not geo_type
  def geo_type
    DATA_TYPES.each { |item|
      return item if send(item)
    }
    nil
  end

  def set_type_if_geography_present
    if type.blank?
      column    = geo_type
      self.type = "GeographicItem::#{column.to_s.camelize}" if column
    end
  end

  # @return [Array] of a point
  def point_to_a(point)
    data = []
    data.push(point.x, point.y)
    data
  end

  # @return [Hash] of a point
  def point_to_hash(point)
    {points: [point_to_a(point)]}
  end

  # @return [Array] of points
  def multi_point_to_a(multi_point)
    data = []
    multi_point.each { |point|
      data.push([point.x, point.y])
    }
    data
  end

  # @return [Hash] of points
  def multi_point_to_hash(_multi_point)
    # when we encounter a multi_point type, we only stick the points into the array, NOT the
    # it's identity as a group
    {points: multi_point_to_a(multi_point)}
  end

  # @return [Array] of points in the line
  def line_string_to_a(line_string)
    data = []
    line_string.points.each { |point|
      data.push([point.x, point.y])
    }
    data
  end

  # @return [Hash] of points in the line
  def line_string_to_hash(line_string)
    {lines: [line_string_to_a(line_string)]}
  end

  # @return [Array] of points in the polygon (exterior_ring ONLY)
  def polygon_to_a(polygon)
    # TODO: handle other parts of the polygon; i.e., the interior_rings (if they exist)
    data = []
    polygon.exterior_ring.points.each { |point|
      data.push([point.x, point.y])
    }
    data
  end

  # @return [Hash] of points in the polygon (exterior_ring ONLY)
  def polygon_to_hash(polygon)
    {polygons: [polygon_to_a(polygon)]}
  end

  # @return [Array] of line_strings as arrays points
  def multi_line_string_to_a(multi_line_string)
    data = []
    multi_line_string.each { |line_string|
      line_data = []
      line_string.points.each { |point|
        line_data.push([point.x, point.y])
      }
      data.push(line_data)
    }
    data
  end

  # @return [Hash] of line_strings as hashes points
  def multi_line_string_to_hash(_multi_line_string)
    {lines: to_a}
  end

  # @return [Array] of arrays points in the polygons (exterior_ring ONLY)
  def multi_polygon_to_a(multi_polygon)
    data = []
    multi_polygon.each { |polygon|
      polygon_data = []
      polygon.exterior_ring.points.each { |point|
        polygon_data.push([point.x, point.y])
      }
      data.push(polygon_data)
    }
    data
  end

  # @return [Hash] of hashes points in the polygons (exterior_ring ONLY)
  def multi_polygon_to_hash(_multi_polygon)
    {polygons: to_a}
  end

  # validation

  # @return [Boolean] iff there is one and only one shape column set
  def some_data_is_provided
    data = []
    DATA_TYPES.each do |item|
      data.push(item) unless send(item).blank?
    end

    errors.add(:base, 'must contain at least one of [point, line_string, etc.].') if data.count == 0
    if data.length > 1
      data.each do |object|
        errors.add(object, 'Only one of [point, line_string, etc.] can be provided.')
      end
    end
    true
  end
end
