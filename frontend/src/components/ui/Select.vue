<template>
  <div :class="props.class">
    <label
      v-if="props.label"
      class="block text-gray-700 text-md mb-1 justify-start float-left"
      :for="props.id"
    >
      {{ props.label }}
    </label>
    <select
      class="shadow appearance-none border bg-white rounded-lg w-full text-base py-2 px-3 leading-tight focus:outline-none focus:shadow-outline"
      v-model="model"
      v-bind="selectProps"
    >
      <option v-for="opt in props.options" :value="opt">{{ opt }}</option>
    </select>
  </div>
</template>

<script lang="ts" setup>
import type { InputTypeHTMLAttribute } from "vue"
import type { Unit } from "../sugar_adjuster/adjustSugar"

interface Props {
  id: string
  type?: InputTypeHTMLAttribute
  label?: string
  class?: string
  options: Unit[]
}

const model = defineModel()
const props = defineProps<Props>()
const selectProps = { ...props, options: undefined, class: undefined }
</script>
