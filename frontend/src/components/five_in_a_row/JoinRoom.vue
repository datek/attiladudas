<template>
  <form @submit="saveRoomName">
    <div class="lg:flex lg:justify-center lg:content-center">
      <Input
        id="input_room_name"
        v-model="data.room"
        :required="true"
        placeholder="Enter room name"
        class="mx-2 my-2 lg:my-0"
      />
      <Input
        id="input_player_name"
        v-model="data.player"
        :required="true"
        placeholder="Enter your name"
        class="mx-2 my-2 lg:my-0"
      />
      <Button type="submit">Join</Button>
    </div>
  </form>
</template>

<script lang="ts" setup>
import { handleError } from "@/utils/errors"
import { reactive } from "vue"
import Button from "../ui/Button.vue"
import { fiveInARowState } from "./state"
import Input from "../ui/Input.vue"
type Data = {
  room: string
  player: string
}

const data = reactive<Data>({ room: "", player: "" })

async function saveRoomName(event: Event) {
  event.preventDefault()
  try {
    await fiveInARowState.webSocketClient?.joinRoom({
      room: data.room,
      player: data.player,
    })
    fiveInARowState.room = data.room
    fiveInARowState.player = data.player
  } catch (e) {
    handleError(String(e))
  }
}
</script>
