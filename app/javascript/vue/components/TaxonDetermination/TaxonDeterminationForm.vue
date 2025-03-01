<template>
  <div>
    <taxon-determination-otu
      v-model="taxonDetermination.otu_id"
      v-model:lock="lockOTU"
      @label="otuLabel = $event"
    />
    <taxon-determination-determiner
      v-model="taxonDetermination.roles_attributes"
      v-model:lock="lockDet"
    />
    <div
      class="horizontal-left-content date-fields separate-bottom separate-top align-end"
    >
      <date-fields
        v-model:year="taxonDetermination.year_made"
        v-model:month="taxonDetermination.month_made"
        v-model:day="taxonDetermination.day_made"
      />
      <date-now
        v-model:year="taxonDetermination.year_made"
        v-model:month="taxonDetermination.month_made"
        v-model:day="taxonDetermination.day_made"
      />
      <lock-component
        v-if="lockDate !== undefined"
        v-model="lockTime"
      />
    </div>
    <div class="flex-separate middle">
      <button
        v-if="createForm"
        type="button"
        id="determination-add-button"
        :disabled="!taxonDetermination.otu_id"
        class="button normal-input button-submit separate-top"
        @click="addDetermination"
      >
        {{
          taxonDetermination.id || taxonDetermination.uuid ? 'Update' : 'Create'
        }}
      </button>
      <button
        v-else
        type="button"
        id="determination-add-button"
        :disabled="!taxonDetermination.otu_id"
        class="button normal-input button-default separate-top"
        @click="addDetermination"
      >
        {{
          taxonDetermination.id || taxonDetermination.uuid ? 'Update' : 'Add'
        }}
      </button>
      <slot name="footer-right"></slot>
    </div>
  </div>
</template>

<script setup>
import { EVENT_TAXON_DETERMINATION_FORM_RESET } from '@/constants/index.js'
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { randomUUID } from '@/helpers'

import TaxonDeterminationOtu from './TaxonDeterminationOtu.vue'
import TaxonDeterminationDeterminer from './TaxonDeterminationDeterminer.vue'
import DateFields from '@/components/ui/Date/DateFields.vue'
import DateNow from '@/components/ui/Date/DateToday.vue'
import makeTaxonDetermination from '@/factory/TaxonDetermination.js'
import LockComponent from '@/components/ui/VLock/index.vue'

const props = defineProps({
  createForm: {
    type: Boolean,
    default: false
  },

  lockDeterminer: {
    type: Boolean,
    default: undefined
  },

  lockOtu: {
    type: Boolean,
    default: undefined
  },

  lockDate: {
    type: Boolean,
    default: undefined
  }
})

const emit = defineEmits([
  'onAdd',
  'update:lockDeterminer',
  'update:lockOtu',
  'update:lockDate'
])

const lockDet = computed({
  get: () => props.lockDeterminer,
  set: (value) => emit('update:lockDeterminer', value)
})

const lockOTU = computed({
  get: () => props.lockOtu,
  set: (value) => emit('update:lockOtu', value)
})

const lockTime = computed({
  get: () => props.lockDate,
  set: (value) => emit('update:lockDate', value)
})

const taxonDetermination = ref(makeTaxonDetermination())
const otuLabel = ref('')

function dateString({ year_made: year, month_made: month, day_made: day }) {
  const date = [year, month, day].filter(Number).join('-')

  return date ? `on ${date}` : ''
}

const setDetermination = (determination = {}) => {
  taxonDetermination.value = { ...makeTaxonDetermination(), ...determination }
}

const getRoleString = (role) =>
  role.organization_id
    ? role.name
    : role?.person?.last_name || role?.last_name || ''

const addDetermination = () => {
  const rolesString = taxonDetermination.value.roles_attributes
    .map(getRoleString)
    .join('; ')
  const rolesLabel = rolesString.length ? 'by ' + rolesString : ''
  const label = `${otuLabel.value} ${rolesLabel} ${dateString(
    taxonDetermination.value
  )}`

  emit('onAdd', {
    uuid: randomUUID(),
    ...taxonDetermination.value,
    object_tag: label
  })

  resetForm()
}

const resetForm = () => {
  const newDetermination = makeTaxonDetermination()

  if (props.lockDate) {
    newDetermination.day_made = taxonDetermination.value.day_made
    newDetermination.month_made = taxonDetermination.value.month_made
    newDetermination.year_made = taxonDetermination.value.year_made
  }

  if (props.lockDeterminer) {
    newDetermination.roles_attributes =
      taxonDetermination.value.roles_attributes
  }

  if (props.lockOtu) {
    newDetermination.otu_id = taxonDetermination.value.otu_id
  }

  setDetermination(newDetermination)
}

onMounted(() =>
  document.addEventListener(EVENT_TAXON_DETERMINATION_FORM_RESET, resetForm)
)
onUnmounted(() =>
  document.removeEventListener(EVENT_TAXON_DETERMINATION_FORM_RESET, resetForm)
)

defineExpose({
  setDetermination,
  resetForm
})
</script>
