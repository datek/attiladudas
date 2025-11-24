<template>
  <form @submit="saveRoomName">
    <div class="lg:flex lg:justify-center lg:content-center">
      <InputField
        id="input_room_name"
        v-model="data.room"
        :required="true"
        placeholder="Enter room name"
      />
      <InputField
        id="input_player_name"
        v-model="data.player"
        :required="true"
        placeholder="Enter your name"
      />
      <Button type="submit">Join</Button>
    </div>
  </form>
</template>

<script lang="ts" setup>
import InputField from "@/components/five_in_a_row/InputField.vue"
import { handleError } from "@/utils/errors"
import { reactive } from "vue"
import Button from "./Button.vue"
import { fiveInARowState } from "./state"
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
