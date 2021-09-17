import { createApp } from 'vue'
import ThemeSelector from 'components/ui/ThemeSelector.vue'

const loadTheme = () => {
  const themeStored = localStorage.getItem('theme')
  const element = document.querySelector('html')

  if (themeStored) {
    element.classList.add(themeStored)
  }
}

function init (element) {
  const app = createApp(ThemeSelector)

  app.mount(element)
}

document.addEventListener('turbolinks:load', () => {
  const element = document.querySelector('#vue-theme-selector')

  if (element) {
    init(element)
  }
})

document.addEventListener('DOMContentLoaded', () => {
  loadTheme()
})