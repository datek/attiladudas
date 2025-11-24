defmodule Server.Web.FiveInARow.Handler do
  alias Server.Web.FiveInARow.Messages.TakeTurn
  alias Server.Web.FiveInARow.Handler, as: Self
  alias Server.Web.FiveInARow.RoomManager
  alias Server.Web.FiveInARow.Room
  alias Server.Web.FiveInARow.Message
  alias Server.Web.FiveInARow.Messages.Join

  defstruct room_name: "",
            room_pid: nil

  def handle_get(conn = %Plug.Conn{}) do
    conn
    |> WebSockAdapter.upgrade(Self, nil, timeout: 60_000)
    |> Plug.Conn.halt()
  end

  def init(_) do
    {:ok, %Self{}}
  end

  def handle_in({msg, [opcode: :text]}, state = %Self{}) do
    case Message.parse(msg) do
      :error ->
        {:push, {:text, Message.new_error("invalid_message")}, state}

      data ->
        handle_message(data, state)
    end
  end

  def handle_info({:DOWN, _, :process, pid, _}, state = %Self{room_pid: room_pid})
      when pid == room_pid do
    {:stop, :normal, state}
  end

  def handle_info({:join, player_name}, state = %Self{}) do
    {:push, {:text, Message.new_join(state.room_name, player_name)}, state}
  end

  def handle_info({:game_update, {cells, next_player, winner}}, state = %Self{}) do
    {:push, {:text, Message.new_game_update(cells, next_player, winner)}, state}
  end

  def handle_info({:pick_side, side}, state = %Self{}) do
    {:push, {:text, Message.new_pick_side(side)}, state}
  end

  def handle_info({:leave, player_name}, state = %Self{}) do
    {:push, {:text, Message.new_leave(player_name)}, state}
  end

  def handle_info({:send_message, message}, state = %Self{}) do
    {:push, {:text, Message.new_send_message(message)}, state}
  end

  defp handle_message(%Message{data: %Join{room: ""}}, state = %Self{}) do
    {:push, {:text, Message.new_error("empty_room_name")}, state}
  end

  defp handle_message(%Message{data: %Join{player: ""}}, state = %Self{}) do
    {:push, {:text, Message.new_error("empty_player_name")}, state}
  end

  defp handle_message(%Message{data: %Join{}}, state = %Self{}) when state.room_name != "" do
    {:push, {:text, Message.new_error("player_already_joined")}, state}
  end

  defp handle_message(%Message{data: data = %Join{}}, state = %Self{}) do
    room = RoomManager.room_process(data.room)

    {response, room_name} =
      case Room.join(room, data.player) do
        :ok ->
          Process.monitor(room)
          {Message.new_ok(), data.room}

        {:error, info} ->
          room_name = if state.room_name == "", do: "", else: state.room_name
          {Message.new_error(info), room_name}
      end

    {:push, {:text, response}, %Self{state | room_name: room_name, room_pid: room}}
  end

  defp handle_message(%Message{type: "SEND_MESSAGE", data: data}, state = %Self{})
       when state.room_pid != nil do
    Room.send_message(state.room_pid, data)
    {:push, {:text, Message.new_ok()}, state}
  end

  defp handle_message(msg = %Message{type: "PICK_SIDE"}, state = %Self{}) do
    Room.pick_side(state.room_pid, msg.data)
    |> handle_room_result(state)
  end

  defp handle_message(msg = %Message{data: %TakeTurn{}}, state = %Self{}) do
    Room.take_turn(state.room_pid, {msg.data.x, msg.data.y})
    |> handle_room_result(state)
  end

  defp handle_message(_, state = %Self{}) do
    {:push, {:text, Message.new_error("invalid_message")}, state}
  end

  defp handle_room_result({:ok, {cells, next_player, winner}}, state = %Self{}) do
    {:push, {:text, Message.new_game_update(cells, next_player, winner)}, state}
  end

  defp handle_room_result({:error, info}, state = %Self{}) do
    {:push, {:text, Message.new_error(info)}, state}
  end
end
