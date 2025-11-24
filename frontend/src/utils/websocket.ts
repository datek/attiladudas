import {
  notificationCollection,
  NotificationItem,
} from "@/components/five_in_a_row/notification/notification"
import type { FieldError } from "./errors"
import { PUBLIC_DATEK_WS_URL } from "./config"

export type WSError = {
  errors: FieldError[]
}

export class WebSocketClient {
  protected _webSocket: WebSocket
  protected _resolve?: (result: any) => void
  protected _reject?: (reason: any) => void

  constructor(
    protected _setGame: (game: UpdateGameData) => void,
    protected _setSide: (side: "X" | "O") => void,
  ) {
    this._webSocket = new WebSocket(`${PUBLIC_DATEK_WS_URL}/ws/five-in-a-row/`)
    this._webSocket.onmessage = (ev) => this.handleMessage(ev)
    this._webSocket.onerror = (ev) => {
      console.error(ev)
    }
  }

  closeConnection() {
    this._webSocket.close()
  }
  sendMessage(message: string) {
    const data: Message = {
      type: "SEND_MESSAGE",
      data: message,
    }

    this._webSocket.send(JSON.stringify(data))
  }

  async joinRoom(joinRoomData: JoinRoomData) {
    await new Promise<void>((resolve, reject) => {
      this._resolve = resolve
      this._reject = reject

      const data: Message = {
        type: "JOIN",
        data: joinRoomData,
      }
      this._webSocket.send(JSON.stringify(data))
    })
  }

  async pickSide(side: Side) {
    await new Promise<void>((resolve, reject) => {
      this._resolve = resolve
      this._reject = reject
      const data: Message = {
        type: "PICK_SIDE",
        data: side,
      }

      this._webSocket.send(JSON.stringify(data))
    })
  }

  async takeTurn(moveData: MoveData) {
    await new Promise<void>((resolve, reject) => {
      this._resolve = resolve
      this._reject = reject

      const data: Message = {
        type: "TAKE_TURN",
        data: moveData,
      }

      this._webSocket.send(JSON.stringify(data))
    })
  }

  protected handleMessage(ev: MessageEvent): void {
    const messageObj = JSON.parse(ev.data) as Message

    if (messageObj.type === "OK" && this._resolve) {
      this._resolve(null)
      this.resetPromiseHandlers()
    } else if (messageObj.type === "BAD_MESSAGE" && this._reject) {
      this._reject(messageObj.data)
      this.resetPromiseHandlers()
    } else if (messageObj.type === "GAME_UPDATE") {
      const data = messageObj.data as UpdateGameData
      if (data.winner) {
        notificationCollection.addItem(
          new NotificationItem("INFO", `${data.winner} has won the game!`),
        )
      }
      this._setGame(data)
    } else if (messageObj.type === "PICK_SIDE") {
      const side = messageObj.data as Side
      const opponentSide = side === "X" ? "O" : "X"
      this._setSide(side)
      notificationCollection.addItem(
        new NotificationItem(
          "INFO",
          `Opponent has picked side ${opponentSide}`,
        ),
      )
    } else if (messageObj.type === "JOIN") {
      const data = messageObj.data as JoinRoomData
      notificationCollection.addItem(
        new NotificationItem("INFO", `${data.player} has joined the game`),
      )
    } else if (messageObj.type === "SEND_MESSAGE") {
      notificationCollection.addItem(
        new NotificationItem("INFO", messageObj.data as string),
      )
    } else if (messageObj.type === "LEAVE") {
      notificationCollection.addItem(
        new NotificationItem("INFO", `${messageObj.data} has left the game`),
      )
    } else {
      console.error(`No handler for message ${messageObj}`)
    }
  }

  protected resetPromiseHandlers() {
    this._resolve = undefined
    this._reject = undefined
  }
}

export type Side = "X" | "O"

export type MessageType =
  | "JOIN"
  | "PICK_SIDE"
  | "GAME_UPDATE"
  | "OK"
  | "SEND_MESSAGE"
  | "BAD_MESSAGE"
  | "TAKE_TURN"
  | "LEAVE"

export type Message = {
  type: MessageType
  data: object | string
}

export type UpdateGameData = {
  next_player: string
  cells: Cells
  winner: string
}

export type Cells = {
  [key: string]: Side | null
}

export type JoinRoomData = {
  room: string
  player: string
}

export type PickSideData = {
  side: string
}

export type MoveData = {
  x: number
  y: number
}
