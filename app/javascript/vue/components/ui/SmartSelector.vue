<template>
  <div ref="smartSelectorElement">
    <div class="separate-bottom horizontal-left-content">
      <switch-components
        class="full_width capitalize"
        v-model="view"
        :options="options"/>
      <default-pin
        v-if="pinSection"
        class="margin-small-left"
        :section="pinSection"
        :type="pinType"
        @getId="getObject"/>
    </div>
    <div
      ref="smartContainer"
      class="smart__selector__container">
      <slot name="header"/>
      <template v-if="!addTabs.includes(view)">
        <div
          class="margin-medium-bottom">
          <autocomplete
            ref="autocompleteElement"
            v-if="autocomplete"
            :id="`smart-selector-${model}-autocomplete`"
            :input-id="inputId"
            placeholder="Search..."
            :url="autocompleteUrl ? autocompleteUrl : `/${model}/autocomplete`"
            param="term"
            :add-params="autocompleteParams"
            label="label_html"
            :clear-after="clear"
            display="label"
            @getItem="getObject($event.id)"/>
          <otu-picker
            v-if="otuPicker"
            :input-id="inputId"
            :clear-after="true"
            @getItem="getObject($event.id)"/>
        </div>
        <slot name="body"/>
        <template v-if="isImageModel">
          <div class="flex-wrap-row">
            <div
              v-for="image in lists[view]"
              :key="image.id"
              class="thumbnail-container margin-small cursor-pointer"
              @click="sendObject(image)">
              <img
                :width="image.alternatives.thumb.width"
                :height="image.alternatives.thumb.height"
                :src="image.alternatives.thumb.image_file_url">
            </div>
          </div>
        </template>
        <template v-else>
          <ul
            v-if="view"
            class="no_bullets smart__selector__ul"
            :class="{ 'flex-wrap-row': inline }">
            <template
              v-for="item in lists[view]"
              :key="item.id">
              <li
                v-if="filterItem(item)"
                class="smart__selector__line">
                <template
                  v-if="buttons">
                  <button
                    type="button"
                    class="button normal-input tag_button"
                    :class="buttonClass"
                    v-html="item[label]"
                    @click.prevent="sendObject(item)"/>
                </template>
                <template
                  v-else>
                  <label
                    class="cursor-pointer"
                    :title="DOMPurify.sanitize(item[label], { FORBID_TAGS: ['i'] })">
                    <input
                      :name="name"
                      @click="sendObject(item)"
                      :value="item"
                      :checked="selectedItem && item.id == selectedItem.id"
                      type="radio">
                    <span v-html="showLabel(item[label])"/>
                  </label>
                </template>
              </li>
            </template>
          </ul>
        </template>
      </template>
      <slot :name="view" />
      <slot />
      <slot name="footer"/>
    </div>
  </div>
</template>

<script setup>

import { ref, watch, computed, onBeforeMount, onBeforeUnmount } from 'vue'
import SwitchComponents from 'components/switch'
import AjaxCall from 'helpers/ajaxCall'
import Autocomplete from 'components/ui/Autocomplete'
import OrderSmart from 'helpers/smartSelector/orderSmartSelector'
import SelectFirst from 'helpers/smartSelector/selectFirstSmartOption'
import DefaultPin from 'components/getDefaultPin'
import OtuPicker from 'components/otu/otu_picker/otu_picker'
import DOMPurify from 'dompurify'
import { shorten } from 'helpers/strings.js'

const props = defineProps({
  modelValue: {
    type: Object,
    default: undefined
  },

  label: {
    type: String,
    default: 'object_tag'
  },

  inline: {
    type: Boolean,
    default: false
  },

  buttons: {
    type: Boolean,
    default: false
  },

  buttonClass: {
    type: String,
    default: 'button-data'
  },

  otuPicker: {
    type: Boolean,
    default: false
  },

  autocompleteParams: {
    type: Object,
    default: undefined
  },

  autocomplete: {
    type: Boolean,
    default: true
  },

  autocompleteUrl: {
    type: String,
    default: undefined
  },

  inputId: {
    type: String,
    default: undefined
  },

  getUrl: {
    type: String,
    default: undefined
  },

  model: {
    type: String,
    default: undefined
  },

  klass: {
    type: String,
    default: undefined
  },

  target: {
    type: String,
    default: undefined
  },

  selected: {
    type: [Array, String],
    default: undefined
  },

  clear: {
    type: Boolean,
    default: true
  },

  pinSection: {
    type: String,
    default: undefined
  },

  pinType: {
    type: String,
    default: undefined
  },

  addTabs: {
    type: Array,
    default: () => []
  },

  params: {
    type: Object,
    default: () => ({})
  },

  customList: {
    type: Object,
    default: () => ({})
  },

  name: {
    type: String,
    required: false,
    default: () => (Math.random().toString(36).substr(2, 5))
  },

  filterIds: {
    type: [Number, Array],
    default: () => []
  },

  filterBy: {
    type: String,
    default: 'id'
  },

  lockView: {
    type: Boolean,
    default: true
  },

  shorten: {
    type: [Number, String],
    default: undefined
  }
})

const emit = defineEmits([
  'update:modelValue',
  'onTabSelected',
  'selected'
])

const selectedItem = computed({
  get () {
    return props.modelValue
  },
  set (value) {
    emit('update:modelValue', value)
  }
})

const smartContainer = ref()
const autocompleteElement = ref()
const smartSelectorElement = ref()

const isImageModel = computed(() => props.model === 'images')
const lists = ref({})
const view = ref()
const options = ref([])
const firstTime = ref(true)

const lastSelected = ref()

watch(view.value, newVal => emit('onTabSelected', newVal))
watch(props.customList, () => addCustomElements())
watch(props.model, () => refresh())

onBeforeMount(() => {
  refresh()
  document.addEventListener('smartselector:update', refresh)
})

onBeforeUnmount(() => {
  document.removeEventListener('smartselector:update', refresh)
})

const getObject = id => {
  const urlRequest = props.getUrl
    ? `${props.getUrl}${id}.json`
    : `/${props.model}/${id}.json`

  AjaxCall('get', urlRequest).then(({ body }) => sendObject(body))
}

const sendObject = item => {
  lastSelected.value = item
  selectedItem.value = item
  emit('selected', item)
}

const filterItem = item => Array.isArray(props.filterIds)
  ? !props.filterIds.includes(item[props.filterBy])
  : props.filterIds !== item[props.filterBy]

const refresh = (forceUpdate = false) => {
  if (alreadyOnLists() && !forceUpdate) return
  const params = Object.assign({}, { klass: props.klass, target: props.target }, props.params)

  AjaxCall('get', `/${props.model}/select_options`, { params }).then(response => {
    lists.value = response.body
    addCustomElements()
    options.value = Object.keys(lists.value)

    if (firstTime.value) {
      view.value = SelectFirst(lists.value, options.value)
      firstTime.value = false
    }

    options.value = options.value.concat(props.addTabs)
    options.value = OrderSmart(options.value)
  }).catch(() => {
    options.value = []
    lists.value = []
    view.value = undefined
  })
}

const addToList = (listName, item) => {
  const index = lists.value[listName].findIndex(({ id }) => id === item.id)

  if (index > -1) {
    lists.value[listName][index] = item
  } else {
    lists.value[listName].push(item)
  }
}

const addCustomElements = () => {
  const keys = Object.keys(props.customList)

  if (keys.length) {
    keys.forEach(key => {
      lists.value[key] = props.customList.value[key]
      if (!lists.value[key]) {
        options.value.push(key)
        options.value = OrderSmart(options.value)
      }
    })
  }
  if (!props.lockView) {
    view.value = SelectFirst(lists.value, options.value)
  }
}

const alreadyOnLists = () => lastSelected.value && !![].concat(...Object.values(lists.value)).find(item => item.id === lastSelected.value.id)

const setFocus = () => {
  autocompleteElement.value.setFocus()
}

const showLabel = label => props.shorten
  ? shorten(label, Number(props.shorten))
  : label

</script>
<style lang="scss">
.smart__selector {

  &__container {}

  &__ul {
    height: 140px;
    overflow-y: auto;
    display: table;
  }

  &__line {
    margin-bottom: 0.5em;
  }
}
</style>
