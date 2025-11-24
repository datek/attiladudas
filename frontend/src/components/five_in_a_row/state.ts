import type {
  Side,
  Cells,
  UpdateGameData,
  WebSocketClient,
} from "@/utils/websocket"
import { reactive } from "vue"

export const tableSize = 11

type FiveInARowState = {
  room: string
  player: string
  side: Side | ""
  game: UpdateGameData
  webSocketClient?: WebSocketClient
}

export const fiveInARowState = reactive<FiveInARowState>({
  room: "",
  player: "",
  side: "",
  game: {
    next_player: "",
    cells: getInitialSquares(),
    winner: "",
  },
})

export function resetFiveInARowState() {
  fiveInARowState.room = ""
  fiveInARowState.player = ""
  fiveInARowState.game = {
    next_player: "",
    cells: getInitialSquares(),
    winner: "",
  }
  fiveInARowState.webSocketClient = undefined
}

function getInitialSquares(): Cells {
  const squares: Cells = {}
  for (let x = 0; x < tableSize; x++) {
    for (let y = 0; y < tableSize; y++) {
      squares[`${x};${y}`] = null
    }
  }

  return squares
}
