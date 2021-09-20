<template>
  <div class="panel content panel-section">
    <h2>Source</h2>
    <div>
      <smart-selector
        class="margin-medium-bottom"
        model="sources"
        klass="Depiction"
        @selected="setSource"/>
      <template v-if="source">
        <hr>
        <div class="middle">
          <span v-html="source.object_tag"/>
          <span
            @click="removeSource"
            class="circle-button button-default btn-undo"/>
        </div>
      </template>
    </div>
  </div>
</template>

<script>

import SmartSelector from 'components/ui/SmartSelector'
import { GetterNames } from '../store/getters/getters.js'
import { MutationNames } from '../store/mutations/mutations.js'

export default {
  components: { SmartSelector },

  computed: {
    source: {
      get () {
        return this.$store.getters[GetterNames.GetSource]
      },
      set (value) {
        this.$store.commit(MutationNames.SetSource, value)
      }
    }
  },

  methods: {
    setSource (value) {
      this.source = value
    },

    removeSource () {
      this.source = undefined
    }
  }
}
</script>
