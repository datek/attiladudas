<template>
  <div :class="props.class">
    <label
      v-if="props.label"
      class="block text-gray-700 text-md mb-1 justify-start float-left"
      :for="props.id"
    >
      {{ props.label }}
    </label>
    <input
      class="shadow appearance-none border rounded-lg w-full py-2 px-3 text-base text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
      v-model="model"
      v-bind="inputProps"
      :placeholder="placeholder"
      :minlength="minlength"
    />
  </div>
</template>

<script lang="ts" setup>
import type { InputTypeHTMLAttribute } from "vue"

interface Props {
  id: string
  type?: InputTypeHTMLAttribute
  label?: string
  class?: string
  placeholder?: string
  step?: number
  inputmode?:
    | "none"
    | "text"
    | "tel"
    | "url"
    | "email"
    | "numeric"
    | "decimal"
    | "search"
  pattern?: string
  required?: boolean
  min?: number
  max?: number
  minlength?: number
}

const model = defineModel()
const props = defineProps<Props>()
const inputProps = { ...props, class: undefined }
</script>
