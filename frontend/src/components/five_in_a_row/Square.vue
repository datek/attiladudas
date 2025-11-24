<template>
  <button :style="buttonStyle" class="square" @click="takeTurn">
    <div :style="divStyle">
      {{ value }}
    </div>
  </button>
</template>

<script lang="ts" setup>
import { squareStyle } from "@/components/five_in_a_row/dynamic_style"
import { handleError } from "@/utils/errors"
import { computed } from "vue"
import { fiveInARowState } from "./state"
import type { Side } from "@/utils/websocket"

const EMPTY_VALUE = "A"

type Props = {
  x: number
  y: number
}

const props = defineProps<Props>()

const value = computed<Side | "A">(() => {
  if (!fiveInARowState.game) return EMPTY_VALUE
  const value = fiveInARowState.game.cells[`${props.x};${props.y}`]
  return value || EMPTY_VALUE
})

const divStyle = computed<string>(() =>
  value.value === EMPTY_VALUE ? "opacity: 0;" : "",
)

const buttonStyle = computed(() => {
  return [
    `width: ${squareStyle.squareSize}px`,
    `height: ${squareStyle.squareSize}px`,
    `font-size: ${squareStyle.fontSize}px`,
  ].join(";")
})

async function takeTurn() {
  try {
    await fiveInARowState.webSocketClient?.takeTurn({
      x: props.x,
      y: props.y,
    })
  } catch (e) {
    handleError(String(e))
  }
}

const errorMessages: Record<string, string> = {
  INVALID_POSITION: "Invalid position",
  NOT_YOUR_TURN: "Not your turn",
  GAME_ALREADY_ENDED: "Game is over",
  NO_ROOM: "You need to pick a side first",
}

// function handleError(error: string) {
//   const errorMsg = errorMessages[error]
//   if (!errorMsg) throw error

//   notificationCollection.addItem(new NotificationItem("DANGER", errorMsg))
// }
</script>

<style scoped>
button.square {
  color: black;
  outline: 0;
  background: #fff;
  border: 1px solid #999;
  font-weight: bold;
  margin-right: -1px;
  margin-top: -1px;
  padding: 0;
  text-align: center;
  cursor: pointer;
}
</style>
