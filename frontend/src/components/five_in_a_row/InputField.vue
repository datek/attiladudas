<template>
  <div class="px-2 my-3 lg:my-0">
    <label
      v-if="label"
      :for="id"
      class="text-sm font-medium text-gray-700 mb-1"
      >{{ label }}</label
    >
    <input
      :class="
        clsx([
          'px-4',
          'py-2',
          'text-base',
          'text-gray-700',
          'bg-white',
          'border',
          'rounded-md',
          'shadow-sm',
          'focus:outline-none',
          'focus:ring',
          'focus:ring-opacity-50',
        ])
      "
      :id="id"
      :type="type"
      :placeholder="placeholder"
      :required="required"
      :value="modelValue"
      @input="onInput"
    />
  </div>
</template>

<script lang="ts" setup>
import clsx from "clsx"
type Props = {
  id: string
  required?: boolean
  modelValue: string
  placeholder?: string
  label?: string
  type?: string
}
const props = defineProps<Props>()

const emit = defineEmits(["update:modelValue"])

function onInput(ev: Event) {
  const target = ev.target as HTMLInputElement
  emit("update:modelValue", target.value)
}
</script>
