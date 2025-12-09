<template>
  <div class="flex flex-col text-center">
    <Notifications />
    <h1>Five in a row</h1>
    <JoinRoom v-if="!fiveInARowState.room && !fiveInARowState.player" />
    <GameBoard v-else />
  </div>
</template>

<script lang="ts" setup>
import JoinRoom from "@/components/five_in_a_row/JoinRoom.vue"
import { onMounted, onUnmounted } from "vue"
import GameBoard from "@/components/five_in_a_row/GameBoard.vue"
import { fiveInARowState, resetFiveInARowState } from "./state"
import { WebSocketClient, type UpdateGameData } from "@/utils/websocket"
import Notifications from "../ui/notification/Notifications.vue"

const updateGame = (game: UpdateGameData) => {
  fiveInARowState.game = game
}
const setSide = (side: "X" | "O") => {
  fiveInARowState.side = side
}

onMounted(() => {
  fiveInARowState.webSocketClient = new WebSocketClient(updateGame, setSide)
})

onUnmounted(() => {
  fiveInARowState.webSocketClient?.closeConnection()
  resetFiveInARowState()
})
</script>
