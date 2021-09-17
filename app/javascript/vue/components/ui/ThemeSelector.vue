<template>
  <div class="field label-above">
    <label>Theme</label>
    <select v-model="themeSelected">
      <option
        v-for="(themeClass, themeName) in THEMES"
        :key="themeName"
        :value="themeClass">
        {{ themeName }}
      </option>
    </select>
  </div>
</template>
<script setup>

import { ref, onBeforeMount, watch } from 'vue'

const THEMES = {
  Dark: 'theme-dark',
  Light: 'theme-light'
}

const themeSelected = ref('')

const updateMode = themeName => {
  localStorage.setItem('theme', themeName)
  setThemeMode(themeName)
}

const setThemeMode = themeName => {
  const element = document.querySelector('html')
  const classList = [...document.querySelector('html').classList]

  classList.forEach(className => { element.classList.remove(className) })
  element.classList.add(themeName)
}

onBeforeMount(() => {
  const themeStored = localStorage.getItem('theme')

  themeSelected.value = themeStored || THEMES.Light
})

watch(themeSelected, newVal => {
  updateMode(newVal)
  setThemeMode(newVal)
})

</script>
