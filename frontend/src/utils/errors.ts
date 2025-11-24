import {
  notificationCollection,
  NotificationItem,
} from "@/components/five_in_a_row/notification/notification"

export type FieldError = {
  location: string
  type: ErrorMappingKey
  context: Object | null
  message: string
}

export function handleError(e: string) {
  const msg = errorTypeToHumanReadable[e]
  if (!msg) {
    throw `Error handling not implemented for ${e}`
  }

  notificationCollection.addItem(new NotificationItem("DANGER", msg))
}

export const errorTypeToHumanReadable: Record<string, string> = {
  player_already_joined: "Player with this name already joined",
  only_one_player_in_room: "Both players must join before you can pick a side",
  side_not_picked: "Side needs to be picked before taking turns",
  not_your_turn: "Not your turn",
  game_ended: "Game has already ended",
}

export type ErrorMappingKey = keyof typeof errorTypeToHumanReadable
