<template>
  <div class="mt-6">
    <span class="mr-4">Pick side:</span>
    <label class="mr-2">
      <input
        v-model="fiveInARowState.side"
        value="X"
        @click="pickSide"
        type="radio"
        name="side"
        :disabled="sidePickingDisabled"
      />
      X
    </label>
    <label class="mr-2">
      <input
        v-model="fiveInARowState.side"
        value="O"
        @click="pickSide"
        type="radio"
        name="side"
        :disabled="sidePickingDisabled"
      />
      O
    </label>
  </div>
  <div v-if="fiveInARowState.game.next_player && !fiveInARowState.game.winner">
    <p>{{ fiveInARowState.game.next_player }} is next</p>
  </div>
  <form class="flex justify-center m-3" @submit="sendMessage">
    <InputField
      id="input_message"
      v-model="data.message"
      type="text"
      placeholder="Send a short message"
    />
    <Button type="submit">Send</Button>
  </form>
  <Squares />
</template>

<script lang="ts" setup>
import { squareStyle } from "@/components/five_in_a_row/dynamic_style"
import Squares from "@/components/five_in_a_row/Squares.vue"
import { handleError } from "@/utils/errors"
import type { Side } from "@/utils/websocket"
import { computed, onMounted, reactive } from "vue"
import Button from "./Button.vue"
import InputField from "./InputField.vue"
import { fiveInARowState } from "./state"

onMounted(() => {
  window.addEventListener("resize", () => {
    squareStyle.setResize()
    squareStyle.resize()
  })
})

const TABLE_SIZE = 11

type Data = {
  side?: Side
  message: string
}

const data = reactive<Data>({
  message: "",
})

async function pickSide(ev: Event) {
  const target = ev.target as HTMLInputElement
  data.side = target.value as Side

  try {
    await fiveInARowState.webSocketClient?.pickSide(data.side)
  } catch (e) {
    handleError(String(e))
    target.checked = false
    fiveInARowState.side = ""
  }
}

const sidePickingDisabled = computed<boolean>(() => {
  return fiveInARowState.side != ""
})

const messageColumnStyle = computed<string>(() => {
  return `flex: none; width: ${TABLE_SIZE * (squareStyle.squareSize + 1) + 2}px;`
})

function sendMessage(ev: Event) {
  ev.preventDefault()
  fiveInARowState.webSocketClient?.sendMessage(data.message)
  data.message = ""
}
</script>
