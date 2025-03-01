# The DataAttribute that has a Predicate that is internally defined in TaxonwWorks.
#
# Internal attributes have stronger semantics that ImportAttributes in that the user has had to first
# create a Predicate (which is a controlled vocabulary subclass), which in turn requires a definition.

# @!attribute controlled_vocabulary_term_id
#   @return [id]
#   The the id of the ControlledVocabularyTerm::Predicate.  Term is referenced as #predicate.
#
class InternalAttribute < DataAttribute
  validates_presence_of :predicate
  validates_uniqueness_of :value, scope: [:attribute_subject_id, :attribute_subject_type, :type, :controlled_vocabulary_term_id, :project_id]

  after_save :update_dwc_occurrences

  # TODO: wrap in generic (reindex_dwc_occurrences method for use in InternalAttribute and elsewhere)
  # TODO: perhaps a Job
  def update_dwc_occurrences
    if DWC_ATTRIBUTE_URIS.values.flatten.include?(predicate.uri)

      if attribute_subject.respond_to?(:set_dwc_occurrence)
        attribute_subject.set_dwc_occurrence
      end

      if attribute_subject.respond_to?(:update_dwc_occurrences)
        attribute_subject.update_dwc_occurrences
      end
    end
  end

  def self.batch_create(params)
    ids = params[:attribute_subject_id]
    params.delete(:attribute_subject_id)

    internal_attributes = []
    InternalAttribute.transaction do
      begin
        ids.each do |id|
          internal_attributes.push InternalAttribute.create!(
            params.merge(
              attribute_subject_id: id
            )
          )
        end
      rescue ActiveRecord::RecordInvalid
        return false
      end
    end
    internal_attributes
  end
end
