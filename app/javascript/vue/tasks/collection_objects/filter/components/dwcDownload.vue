<template>
  <div>
    <slot :action="action">
      <v-btn
        color="primary"
        medium
        @click="setModalView(true)"
      >
        Download DwC
      </v-btn>
    </slot>
    <v-modal
      @close="setModalView(false)"
      :container-style="{ width: '700px', minHeight: '200px' }"
      v-if="showModal"
    >
      <template #header>
        <h3>Download DwC</h3>
      </template>
      <template #body>
        <v-spinner
          v-if="isLoading"
          legend="Loading predicates..."
        />
        <ul class="no_bullets">
          <li
            v-for="item in checkboxParameters"
            :key="item.parameter"
          >
            <label>
              <input
                type="checkbox"
                :disabled="item.disabled"
                v-model="includeParameters[item.parameter]"
              />
              {{ item.label }}
            </label>
          </li>
        </ul>
        <div class="margin-small-top">
          <h3>Filter by predicates</h3>
        </div>
        <div>
          <v-btn
            class="margin-small-right"
            color="primary"
            medium
            @click="
              () => {
                predicateParams.collection_object_predicate_id =
                  collectionObjects.map((co) => co.id)
                predicateParams.collecting_event_predicate_id =
                  collectingEvents.map((ce) => ce.id)
              }
            "
          >
            Select all
          </v-btn>
          <v-btn
            color="primary"
            medium
            @click="
              () => {
                predicateParams.collection_object_predicate_id = []
                predicateParams.collecting_event_predicate_id = []
              }
            "
          >
            Unselect all
          </v-btn>
        </div>
        <div class="margin-small-bottom dwc-download-predicates">
          <div>
            <table v-if="collectingEvents.length">
              <thead>
                <tr>
                  <th>
                    <input
                      v-model="checkAllCe"
                      type="checkbox"
                    />
                  </th>
                  <th class="full_width">Collecting events</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="item in collectingEvents"
                  :key="item.id"
                >
                  <td>
                    <input
                      type="checkbox"
                      :value="item.id"
                      v-model="predicateParams.collecting_event_predicate_id"
                    />
                  </td>
                  <td>
                    <span v-html="item.object_tag" />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div>
            <table v-if="collectionObjects.length">
              <thead>
                <tr>
                  <th>
                    <input
                      v-model="checkAllCo"
                      type="checkbox"
                    />
                  </th>
                  <th class="full_width">Collection objects</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="item in collectionObjects"
                  :key="item.id"
                >
                  <td>
                    <input
                      type="checkbox"
                      :value="item.id"
                      v-model="predicateParams.collection_object_predicate_id"
                    />
                  </td>
                  <td>
                    <span v-html="item.object_tag" />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div>
            <table v-if="extensionMethodNames.length">
              <thead>
                <tr>
                  <th>
                    <input
                      v-model="checkAllExtensionMethods"
                      type="checkbox"
                    />
                  </th>
                  <th class="full_width">Internal values</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="item in extensionMethodNames"
                  :key="item.id"
                >
                  <td>
                    <input
                      type="checkbox"
                      :value="item"
                      v-model="
                        selectedExtensionMethods.taxonworks_extension_methods
                      "
                    />
                  </td>
                  <td>
                    <span v-html="item" />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div class="margin-medium-top">
          <VBtn
            color="create"
            medium
            @click="download"
          >
            Download
          </VBtn>
        </div>
      </template>
    </v-modal>
    <ConfirmationModal ref="confirmationModalRef" />
  </div>
</template>
<script setup>
import { computed, reactive, ref, onBeforeMount, watch } from 'vue'
import { RouteNames } from '@/routes/routes.js'
import { DwcOcurrence } from '@/routes/endpoints'
import ConfirmationModal from '@/components/ConfirmationModal.vue'
import VBtn from '@/components/ui/VBtn/index.vue'
import VModal from '@/components/ui/Modal.vue'
import VSpinner from '@/components/ui/VSpinner.vue'

const checkboxParameters = [
  {
    label: 'Include biological associations as recource relationship',
    parameter: 'biological_associations_extension'
  },
  {
    label: 'Include media extension',
    parameter: 'media_extension',
    disabled: true
  }
]

const props = defineProps({
  params: {
    type: Object,
    required: true
  },

  total: {
    type: Number,
    required: true
  },

  selectedIds: {
    type: Array,
    default: () => []
  }
})

const confirmationModalRef = ref()
const showModal = ref(false)
const isLoading = ref(false)
const collectingEvents = ref([])
const collectionObjects = ref([])
const includeParameters = ref({})
const predicateParams = reactive({
  collecting_event_predicate_id: [],
  collection_object_predicate_id: []
})
const extensionMethodNames = ref([])
const selectedExtensionMethods = reactive({
  taxonworks_extension_methods: []
})

const getFilterParams = (params) => {
  const entries = Object.entries({ ...params, ...predicateParams }).filter(
    ([key, value]) => !Array.isArray(value) || value.length
  )
  const data = Object.fromEntries(entries)

  data.per = props.total
  delete data.page

  return data
}

const checkAllCe = computed({
  get: () =>
    predicateParams.collecting_event_predicate_id.length ===
    collectingEvents.value.length,
  set: (isChecked) => {
    predicateParams.collecting_event_predicate_id = isChecked
      ? collectingEvents.value.map((co) => co.id)
      : []
  }
})

const checkAllCo = computed({
  get: () =>
    predicateParams.collection_object_predicate_id.length ===
    collectionObjects.value.length,
  set: (isChecked) => {
    predicateParams.collection_object_predicate_id = isChecked
      ? collectionObjects.value.map((co) => co.id)
      : []
  }
})

const checkAllExtensionMethods = computed({
  get: () =>
    selectedExtensionMethods.taxonworks_extension_methods.length ===
    extensionMethodNames.value.length,
  set: (isChecked) => {
    selectedExtensionMethods.taxonworks_extension_methods = isChecked
      ? extensionMethodNames.value
      : []
  }
})

function download() {
  const downloadParams = props.selectedIds.length
    ? { collection_object_id: props.selectedIds }
    : getFilterParams(props.params)

  DwcOcurrence.generateDownload({
    collection_object_query: {
      ...downloadParams
    },
    ...includeParameters.value,
    ...predicateParams,
    ...selectedExtensionMethods
  }).then((_) => {
    openGenerateDownloadModal()
  })
}

function setModalView(value) {
  showModal.value = value
}

function action() {
  setModalView(true)
}

async function openGenerateDownloadModal() {
  await confirmationModalRef.value.show({
    title: 'Generating Download',
    message: `It will be available shortly on the <a href="${RouteNames.DwcDashboard}">DwC Dashboard</a>`,
    okButton: 'Close',
    typeButton: 'default'
  })

  setModalView(false)
}

onBeforeMount(async () => {
  isLoading.value = true

  const [predicates, extensions] = await Promise.all([
    DwcOcurrence.predicates(),
    DwcOcurrence.taxonworksExtensionMethods()
  ])

  isLoading.value = false

  collectingEvents.value = predicates.body.collecting_event
  collectionObjects.value = predicates.body.collection_object

  extensionMethodNames.value = extensions.body
})

watch(showModal, (newVal) => {
  if (newVal) {
    predicateParams.collection_object_predicate_id = []
    predicateParams.collecting_event_predicate_id = []
    selectedExtensionMethods.taxonworks_extension_methods = []
  }
})
</script>
<style>
.dwc-download-predicates {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 1em;
}
</style>
