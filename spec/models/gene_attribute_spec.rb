require 'rails_helper'

RSpec.describe GeneAttribute, type: :model do
  let(:gene_attribute) {GeneAttribute.new}

  context 'validation' do
    context 'fails when not given' do
      before(:each) { gene_attribute.valid? }

      specify 'descriptor' do
        expect(gene_attribute.errors.include?(:descriptor)).to be_truthy
      end

      specify 'sequence' do
        expect(gene_attribute.errors.include?(:sequence)).to be_truthy
      end
    end
    
    context 'passes when provided a' do
      specify 'descriptor_id and sequence_id' do
        gene_attribute = FactoryGirl.create(:valid_gene_attribute)
        expect(gene_attribute.valid?).to be_truthy
      end
    end
  end
end
