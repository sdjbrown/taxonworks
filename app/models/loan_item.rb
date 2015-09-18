
# A loan item is a CollectionObject, Container, or historical reference to 
# something that has been loaned.
#
# @!attribute loan_id
#   @return [Integer]
#   Id of the loan 
#
# @!attribute loan_object_type
#   @return [String]
#   Polymorphic- one of Container, CollectionObject, or Otu 
#
# @!attribute loan_object_id
#   @return [Integer]
#   Polymorphic, the id of the Container, CollectionObject or Otu
#
# @!attribute date_returned
#   @return [DateTime]
#   The date the item was returned. 
#
# @!attribute collection_object_status
#   @return [String]
#   @todo
#
# @!attribute position
#   @return [Integer]
#   Sorts the items in relation to the loan. 
#
# @!attribute project_id
#   @return [Integer]
#   the project ID
#
class LoanItem < ActiveRecord::Base
  acts_as_list scope: :loan

  include Housekeeping
  include Shared::IsData
  include Shared::DataAttributes
  include Shared::Notable
  include Shared::Taggable

  belongs_to :loan
  belongs_to :loan_item_object, polymorphic: true

  validates_presence_of :loan_item_object_id, :loan_item_object_type

  validates :loan_id, presence: true
  validates_uniqueness_of :loan, scope: [:loan_item_object_type, :loan_item_object_id] 
  
  validate :total_provided_only_when_otu
  validates_inclusion_of :loan_item_object_type, in: %w{Otu CollectionObject Container}

  protected

  def total_provided_only_when_otu
    errors.add(:total, 'total only providable when item is an otu') if total && loan_item_object_type != 'Otu'
  end


end
