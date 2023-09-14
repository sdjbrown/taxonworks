module Queries
  module DataAttribute
    class Filter < Query::Filter

      include Concerns::Polymorphic
      polymorphic_klass(::DataAttribute)

      PARAMS = [
        *::DataAttribute.related_foreign_keys.map(&:to_sym),
        :value,
        :controlled_vocabulary_term_id,
        :import_predicate,
        :type,
        :attribute_subject_type,
        :attribute_subject_id,
        :data_attribute_id,
        controlled_vocabulary_term_id: [],
        data_attribute_id: []
      ].freeze

      # Params specific to DataAttribute
      attr_accessor :value

      # @return [Array]
      attr_accessor :controlled_vocabulary_term_id

      attr_accessor :import_predicate

      attr_accessor :type

      attr_accessor :attribute_subject_type

      attr_accessor :attribute_subject_id

      attr_accessor :data_attribute_id

      # @params params [ActionController::Parameters]
      def initialize(query_params)
        super

        @attribute_subject_id = params[:attribute_subject_id]
        @attribute_subject_type = params[:attribute_subject_type]
        @controlled_vocabulary_term_id = params[:controlled_vocabulary_term_id]
        @data_attribute_id = params[:data_attribute_id]
        @import_predicate = params[:import_predicate]
        @type = params[:type]
        @value = params[:value]

        set_polymorphic_params(params)
      end

      def data_attribute_id
        [@data_attribute_id].flatten.compact
      end

      def controlled_vocabulary_term_id
        [@controlled_vocabulary_term_id].flatten.compact
      end

      # TODO - rename matching to _facet

      # @return [Arel::Node, nil]
      def matching_attribute_subject_type
        attribute_subject_type.present? ? table[:attribute_subject_type].eq(attribute_subject_type)  : nil
      end

      # @return [Arel::Node, nil]
      def matching_attribute_subject_id
        attribute_subject_id.present? ? table[:attribute_subject_id].eq(attribute_subject_id)  : nil
      end

      # @return [Arel::Node, nil]
      def matching_value
        value.blank? ? nil : table[:value].eq(value)
      end

      # @return [Arel::Node, nil]
      def matching_import_predicate
        import_predicate.blank? ? nil : table[:import_predicate].eq(import_predicate)
      end

      # @return [Arel::Node, nil]
      def matching_type
        type.blank? ? nil : table[:type].eq(type)
      end

      # @return [Arel::Node, nil]
      def matching_controlled_vocabulary_term_id
        controlled_vocabulary_term_id.empty? ? nil : table[:controlled_vocabulary_term_id].eq_any(controlled_vocabulary_term_id)
      end


      #
      # TODO: generalize to a single method
      #
      def collection_object_query_facet
        return nil if collection_object_query.nil?
        s = 'WITH query_co_da AS (' + collection_object_query.all.to_sql + ') ' +
          ::DataAttribute
          .joins("JOIN query_co_da as query_co_da1 on data_attributes.attribute_subject_id = query_co_da1.id AND data_attributes.attribute_subject_type = 'CollectionObject'")
          .to_sql

        ::DataAttribute.from('(' + s + ') as data_attributes').distinct
      end

      def collecting_event_query_facet
        return nil if collecting_event_query.nil?
        s = 'WITH query_ce_da AS (' + collecting_event_query.all.to_sql + ') ' +
          ::DataAttribute
          .joins("JOIN query_ce_da as query_ce_da1 on data_attributes.attribute_subject_id = query_ce_da1.id AND data_attributes.attribute_subject_type = 'CollectingEvent'")
          .to_sql

        ::DataAttribute.from('(' + s + ') as data_attributes').distinct
      end

      def taxon_name_query_facet
        return nil if taxon_name_query.nil?
        s = 'WITH query_tn_da AS (' + taxon_name_query.all.to_sql + ') ' +
          ::DataAttribute
          .joins("JOIN query_tn_da as query_tn_da1 on data_attributes.attribute_subject_id = query_tn_da1.id AND data_attributes.attribute_subject_type = 'TaxonName'")
          .to_sql

        ::DataAttribute.from('(' + s + ') as data_attributes').distinct
      end

      def merge_clauses
        [
          taxon_name_query_facet,
          collecting_event_query_facet,
          collection_object_query_facet
        ]
      end

      def and_clauses
        [
          matching_type,
          matching_value,
          matching_import_predicate,
          matching_attribute_subject_id,
          matching_attribute_subject_type,
          matching_controlled_vocabulary_term_id,
        ]
      end

    end
  end
end
