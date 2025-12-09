<template>
  <button
    class="bg-primary px-3 text-white text-base py-2 rounded-lg shadow-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-75 disabled:bg-slate-400"
    :type="type"
    :disabled="disabled"
  >
    <slot></slot>
  </button>
</template>

<script lang="ts" setup>
type Props = {
  type: "button" | "submit" | "reset" | undefined
  disabled?: boolean
}

defineProps<Props>()
</script>
