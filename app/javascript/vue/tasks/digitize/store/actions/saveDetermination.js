import { MutationNames } from '../mutations/mutations'
import { CreateTaxonDetermination, UpdateTaxonDetermination } from '../../request/resources'
import ValidateDetermination from '../../validations/determination'
import TaxonDetermination from '../../const/taxonDetermination'

export default function ({ commit, state }, determination) {
  function addToList(taxonDetermination) {
    if(!state.taxon_determinations.find((item) => { return item.id == taxonDetermination.id})) {
      commit(MutationNames.AddTaxonDetermination, taxonDetermination)
    }    
  }
  return new Promise((resolve, reject) => {
    let taxon_determination = determination
    taxon_determination.biological_collection_object_id = state.collection_object.id

    if(ValidateDetermination(taxon_determination)) {
      if(taxon_determination.id) {
        UpdateTaxonDetermination(taxon_determination).then(response => {
          //commit(MutationNames.SetTaxonDetermination, response)
          addToList(response)
          resolve(response)
        }, (response) => {
          TW.workbench.alert.create(JSON.stringify(Object.keys(response.body).map(key => { return response.body[key] }).join('<br>')), 'error')
          reject(response)
        })
      }
      else {
        CreateTaxonDetermination(taxon_determination).then(response => {
          state.collection_object.object_tag = response.collection_object.object_tag
          addToList(response)
          resolve(response)
        }, (response) => {
          TW.workbench.alert.create(JSON.stringify(Object.keys(response.body).map(key => { return response.body[key] }).join('<br>')), 'error')
          reject(response)
        })
      }
    }
    else {
      resolve()
    }
  })
}