<template>
  <div>
    <h2>Trip code</h2>
    <fieldset>
      <legend>Namespace</legend>
      <div class="horizontal-left-content middle field separate-bottom">
        <smart-selector
          class="full_width"
          ref="smartSelector"
          model="namespaces"
          target="CollectingEvent"
          klass="CollectingEvent"
          @selected="setTripCode"
        />
      </div>
      <template v-if="identifier.namespace_id">
        <hr />
        <div class="middle flex-separate">
          <p class="separate-right">
            <span data-icon="ok" />
            <span
              v-html="namespaceSelected ? namespaceSelected : identifier.cached"
            />
          </p>
          <span
            class="circle-button button-default btn-undo"
            @click="identifier.namespace_id = undefined"
          />
        </div>
      </template>
    </fieldset>
    <div class="separate-top">
      <label>Identifier</label>
      <div class="horizontal-left-content field">
        <input
          type="text"
          v-model="identifier.identifier"
        />
        <validate-component
          v-if="identifier.namespace_id"
          class="separate-left"
          :show-message="checkValidation"
          legend="Namespace and identifier needs to be set to be saved."
        />
      </div>
    </div>
  </div>
</template>

<script>
import SmartSelector from '@/components/ui/SmartSelector.vue'
import { GetterNames } from '../../../../store/getters/getters'
import { MutationNames } from '../../../../store/mutations/mutations.js'

import validateComponent from '../../../shared/validate.vue'
import validateIdentifier from '../../../../validations/namespace.js'

export default {
  components: {
    validateComponent,
    SmartSelector
  },

  computed: {
    identifier: {
      get() {
        return this.$store.getters[GetterNames.GetCollectingEventIdentifier]
      },
      set(value) {
        this.$store.commit(MutationNames.SetCollectingEventIdentifier, value)
      }
    },

    checkValidation() {
      return !validateIdentifier({
        namespace_id: this.identifier.namespace_id,
        identifier: this.identifier.identifier
      })
    }
  },

  data() {
    return {
      delay: 1000,
      namespaceSelected: undefined
    }
  },

  methods: {
    setTripCode(identifier) {
      this.identifier.namespace_id = identifier.id
      this.namespaceSelected = identifier.name
    }
  }
}
</script>

<style scoped>
.validate-identifier {
  border: 1px solid red;
}
</style>
