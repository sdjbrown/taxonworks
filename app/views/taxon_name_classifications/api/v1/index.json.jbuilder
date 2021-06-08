json.array!(@taxon_names) do |taxon_name|
  json.partial! '/taxon_name_classification/api/v1/base_attributes', taxon_name_classification: taxon_name_classification
end
