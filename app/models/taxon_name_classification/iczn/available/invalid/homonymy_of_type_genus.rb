class TaxonNameClassification::Iczn::Available::Invalid::HomonymyOfTypeGenus < TaxonNameClassification::Iczn::Available::Invalid

#  NOMEN_URI='http://purl.obolibrary.org/obo/NOMEN_0000043'.freeze

  LABEL = 'invalid due to homonymy of type genus'.freeze

  def self.disjoint_taxon_name_classes
    self.parent.disjoint_taxon_name_classes +
        self.collect_to_s(TaxonNameClassification::Iczn::Available::Invalid,
                          TaxonNameClassification::Iczn::Available::Invalid::Homonym,
                          TaxonNameClassification::Iczn::Available::Invalid::SuppressionOfTypeGenus)
  end

  def sv_not_specific_classes
    true
  end
end