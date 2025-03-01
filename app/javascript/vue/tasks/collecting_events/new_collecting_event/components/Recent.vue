<template>
  <div>
    <spinner-component
      v-if="isLoading"
      full-screen
    />
    <button
      @click="showModalView(true)"
      class="button normal-input button-default button-size separate-left"
      type="button"
    >
      Recent
    </button>
    <modal-component
      :container-style="{ width: '90%' }"
      @close="showModalView(false)"
    >
      <template #header>
        <h3>Recent collecting events</h3>
      </template>
      <template #body>
        <table class="full_width">
          <thead>
            <tr>
              <th class="full_width">Object tag</th>
              <th />
            </tr>
          </thead>
          <tbody>
            <tr
              class="contextMenuCells"
              v-for="(item, index) in collectingEvents"
              :key="item.id"
            >
              <td v-html="item.object_tag" />
              <td>
                <div class="horizontal-left-content gap-small">
                  <span
                    class="button circle-button btn-edit"
                    @click="selectCollectingEvent(item)"
                  />
                  <span
                    class="button circle-button btn-delete button-delete"
                    @click="removeCollectingEvent(index)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </modal-component>
  </div>
</template>

<script>
import SpinnerComponent from '@/components/ui/VSpinner'
import ModalComponent from '@/components/ui/Modal'
import { CollectingEvent } from '@/routes/endpoints'

export default {
  components: {
    SpinnerComponent,
    ModalComponent
  },

  emits: ['close', 'select'],

  data() {
    return {
      collectingEvents: [],
      isLoading: false,
      showModal: false
    }
  },

  created() {
    this.isLoading = true
    CollectingEvent.where({ per: 10, recent: true })
      .then((response) => {
        this.collectingEvents = response.body
      })
      .finally(() => {
        this.isLoading = false
      })
  },

  methods: {
    showModalView(value) {
      this.$emit('close', value)
    },

    removeCollectingEvent(index) {
      if (
        window.confirm(
          "You're trying to delete this record. Are you sure want to proceed?"
        )
      ) {
        CollectingEvent.destroy(this.collectingEvents[index].id).then(() => {
          this.collectingEvents.splice(index, 1)
        })
      }
    },

    selectCollectingEvent(collectingEvent) {
      this.$emit('select', collectingEvent)
      this.showModalView(false)
    }
  }
}
</script>
