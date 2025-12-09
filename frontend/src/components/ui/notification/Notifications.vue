<template>
  <div
    v-for="(item, index) in notificationCollection.items"
    :key="index"
    :class="
      // @ts-ignore
      clsx([
        'text-center',
        'notification',
        'top',
        'text-white',
        'py-2',
        'my-3',
        'rounded-xl',
        ...item.classes,
      ])
    "
    :style="item.styleString"
  >
    {{ item.message }}
  </div>
</template>

<script lang="ts" setup>
import clsx from "clsx"
import { notificationCollection } from "./notification"
</script>

<style scoped>
.notification.top {
  z-index: 100;
}

.notification.mobile {
  position: absolute;
  width: 70%;
  left: 15%;
}

.notification.desktop {
  position: absolute;
  width: 25%;
  left: 70%;
}

.fade-out {
  animation: fadeOut ease 0.5s;
}

@keyframes fadeOut {
  0% {
    opacity: 1;
  }
  100% {
    opacity: 0;
  }
}
</style>
