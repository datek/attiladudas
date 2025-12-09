<template>
  <div :class="props.class">
    <label
      v-if="props.label"
      class="block text-gray-700 text-md mb-1 justify-start float-left"
      :for="props.id"
    >
      {{ props.label }}
    </label>
    <textarea
      class="shadow appearance-none border rounded-lg w-full py-2 px-3 text-base text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
      v-bind="inputProps"
      v-model="model"
      :placeholder="placeholder"
      :rows="rows"
      :cols="cols"
      :minlength="minlength"
    />
  </div>
</template>

<script lang="ts" setup>
interface Props {
  id: string
  label?: string
  class?: string
  placeholder?: string
  step?: number
  rows?: number
  cols?: number
  required?: boolean
  minlength?: number
}

const model = defineModel<string>()
const props = defineProps<Props>()
const inputProps = { ...props, class: undefined }
</script>
