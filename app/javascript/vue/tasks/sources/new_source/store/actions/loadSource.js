import { ActionNames } from './actions'
import { MutationNames } from '../mutations/mutations'
import { Source, Documentation } from '@/routes/endpoints'
import { SOURCE } from '@/constants'

import setParam from '@/helpers/setParam'

export default ({ state, commit, dispatch }, id) => {
  dispatch(ActionNames.ResetSource)

  Source.find(id, { extend: 'roles' }).then(
    ({ body }) => {
      const source = body
      const authors = source.author_roles
      const editors = source.editor_roles
      const people = [].concat(authors, editors).filter((item) => item)

      source.roles_attributes = people
      commit(MutationNames.SetSource, source)
      dispatch(ActionNames.LoadSoftValidations, body.global_id)

      Documentation.where({
        documentation_object_id: id,
        documentation_object_type: SOURCE
      }).then(({ body }) => {
        commit(MutationNames.SetDocumentation, body)
      })

      setParam('/tasks/sources/new_source', 'source_id', body.id)
      state.settings.lastSave = 0
      state.settings.lastEdit = 0
    },
    (_) => {
      TW.workbench.alert.create('No source was found with that ID.', 'alert')
      history.pushState(null, null, '/tasks/sources/new_source')
    }
  )
}
