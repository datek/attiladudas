defmodule Server.Web.FiveInARow.HandlerTest do
  use ExUnit.Case
  alias Server.Web.FiveInARow.HandlerTest, as: Fixture
  alias Server.Web.FiveInARow.Room
  alias Server.FiveInARow.Game
  alias Server.Web.FiveInARow.RoomManager
  alias Server.Web.FiveInARow.Message

  defstruct [
    :client1,
    :client2,
    :client3,
    :room_name,
    :player1,
    :player2,
    :player3
  ]

  setup do
    client1 = WSTestClient.start!()
    client2 = WSTestClient.start!()
    client3 = WSTestClient.start!()
    room_name = "room-1"

    on_exit(fn ->
      Enum.map([client1, client2, client3], fn client -> WSTestClient.stop(client) end)
      assert ensure_room_stopped(room_name)
    end)

    {:ok,
     fixture: %Fixture{
       client1: client1,
       client2: client2,
       client3: client3,
       room_name: room_name,
       player1: "Giskard",
       player2: "Daneel",
       player3: "Fastolfe"
     }}
  end

  defp ensure_room_stopped(room_name) do
    case Room.where_is(room_name) do
      nil ->
        true

      pid ->
        Process.monitor(pid)

        if Process.alive?(pid) do
          receive do
            {:DOWN, _, :process, ^pid, :normal} -> true
          after
            200 ->
              Process.exit(pid, :kill)
              false
          end
        else
          true
        end
    end
  end

  test "Empty room name is invalid", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join("", fixture.player1)

    # when
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "empty_room_name"
  end

  test "Empty player name is invalid", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, "")

    # when
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "empty_player_name"
  end

  test "Player 1 connects", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)

    # when
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "OK"
  end

  test "Player 2 can't connect from same client", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "player_already_joined"
  end

  test "Player 2 connects", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "OK"

    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "JOIN"
    assert msg.data.player == fixture.player2
  end

  test "Player 2 can't connect with same name", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, "Daneel")
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    # when
    WSTestClient.send_msg(fixture.client2, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "player_already_joined"
  end

  test "Room is full with 2 players", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)

    # when
    WSTestClient.send_msg(fixture.client3, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client3)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "room_is_full"
  end

  test "Player picks side", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    # when
    WSTestClient.send_msg(fixture.client1, Message.new_pick_side(:X))

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "GAME_UPDATE"
    assert msg.data.next_player == fixture.player1

    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "PICK_SIDE"
    assert msg.data == :O

    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "GAME_UPDATE"
    assert msg.data.next_player == fixture.player1
  end

  test "Both players must join before picking side", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    # when
    WSTestClient.send_msg(fixture.client1, Message.new_pick_side(:X))

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "only_one_player_in_room"
  end

  test "Other player can't pick side", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    WSTestClient.send_msg(fixture.client1, Message.new_pick_side(:X))
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client1)
    %Message{type: "PICK_SIDE"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client2)

    # when
    WSTestClient.send_msg(fixture.client2, Message.new_pick_side(:O))

    # then
    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "side_already_decided"
  end

  test "Room is being freed up when players leave", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    room = Room.where_is(fixture.room_name)
    Process.monitor(room)

    # when
    Enum.map([fixture.client1, fixture.client2], fn client -> WSTestClient.stop(client) end)

    # then
    room_stopped =
      receive do
        {:DOWN, _, :process, ^room, :normal} -> true
      after
        100 -> false
      end

    assert room_stopped

    client1 = WSTestClient.start!()
    WSTestClient.send_msg(client1, msg)

    msg = WSTestClient.receive_msg(client1)
    assert msg.type == "OK"

    # cleanup
    WSTestClient.stop(client1)
  end

  test "Another player can connect if one player leaves", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_pick_side(:O)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "PICK_SIDE"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client1)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client2)

    WSTestClient.stop(fixture.client1)
    %Message{type: "LEAVE"} = WSTestClient.receive_msg(fixture.client2)

    # when
    msg = Message.new_join(fixture.room_name, fixture.player3)
    WSTestClient.send_msg(fixture.client3, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client3)
    assert msg.type == "OK"

    msg = WSTestClient.receive_msg(fixture.client3)
    assert msg.type == "PICK_SIDE"
    assert msg.data == :O

    msg = WSTestClient.receive_msg(fixture.client3)
    assert msg.type == "GAME_UPDATE"

    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "JOIN"
  end

  test "Player is being disconnected when room process dies", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)
    room = RoomManager.room_process(fixture.room_name)

    # when
    Process.exit(room, :kill)

    # then
    assert WSTestClient.receive_msg(fixture.client1) == :disconnect
  end

  test "Player takes turn", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_pick_side(:O)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "PICK_SIDE"} = WSTestClient.receive_msg(fixture.client1)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client1)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client2)

    position = {1, 2}
    msg = Message.new_take_turn(position)

    # when
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "GAME_UPDATE"
    assert msg.data.next_player == fixture.player2

    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "GAME_UPDATE"
    assert msg.data.next_player == fixture.player2
  end

  test "Player can't take turn until side is picked - 1", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_take_turn({1, 2})
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "side_not_picked"
  end

  test "Player can't take turn until side is picked - 2", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_take_turn({1, 2})
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "side_not_picked"
  end

  test "Player can't take 2 turns", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_pick_side(:X)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "PICK_SIDE"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client1)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client2)

    msg = Message.new_take_turn({1, 2})
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "GAME_UPDATE"} = WSTestClient.receive_msg(fixture.client1)

    # when
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "not_your_turn"
  end

  test "Player can't take turn if game has ended", %{fixture: fixture = %Fixture{}} do
    # given
    game = %Game{winner: fixture.player1}
    Room.start_link(fixture.room_name, 60_000, game)

    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_take_turn({1, 2})
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
    assert msg.data == "game_ended"
  end

  test "Player sends message to opponent", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    msg = Message.new_join(fixture.room_name, fixture.player2)
    WSTestClient.send_msg(fixture.client2, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client2)
    %Message{type: "JOIN"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_send_message("hi")
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    assert WSTestClient.receive_msg(fixture.client1) == %Message{type: "OK"}
    msg = WSTestClient.receive_msg(fixture.client2)
    assert msg.type == "SEND_MESSAGE"
    assert msg.data == "hi"
  end

  test "Player sends message to nobody", %{fixture: fixture = %Fixture{}} do
    # given
    msg = Message.new_join(fixture.room_name, fixture.player1)
    WSTestClient.send_msg(fixture.client1, msg)
    %Message{type: "OK"} = WSTestClient.receive_msg(fixture.client1)

    # when
    msg = Message.new_send_message("hi")
    WSTestClient.send_msg(fixture.client1, msg)

    # then
    assert WSTestClient.receive_msg(fixture.client1) == %Message{type: "OK"}
  end

  test "Returns error on invalid mesage", %{fixture: fixture = %Fixture{}} do
    # when
    WSTestClient.send_msg(fixture.client1, "invalid")

    # then
    msg = WSTestClient.receive_msg(fixture.client1)
    assert msg.type == "BAD_MESSAGE"
  end
end

defmodule WSTestClient do
  use WebSockex

  alias WSTestClient, as: Self
  alias Server.Web.FiveInARow.Message

  defstruct queue: nil,
            receiver: nil

  def receive_msg(client) do
    send(client, {:receive, self()})

    receive do
      msg ->
        case(is_binary(msg)) do
          true -> Message.parse(msg)
          _ -> msg
        end
    after
      500 -> {:error, :timeout}
    end
  end

  def send_msg(client, msg) do
    WebSockex.send_frame(client, {:text, msg})
  end

  def start!() do
    {:ok, client} =
      WebSockex.start(
        "ws://127.0.0.1:#{Application.fetch_env!(:server, :http_port)}/ws/five-in-a-row/",
        __MODULE__,
        %Self{queue: :queue.new()}
      )

    :ok = receive_msg(client)
    client
  end

  def stop(client) do
    Process.exit(client, :kill)
  end

  @impl true
  def handle_connect(_conn, state = %Self{}) do
    queue = :queue.in(:ok, state.queue)
    {:ok, %Self{state | queue: queue}}
  end

  @impl true
  def handle_disconnect(_conn, state = %Self{}) when state.receiver == nil do
    queue = :queue.in(:disconnect, state.queue)
    {:ok, %Self{state | queue: queue}}
  end

  @impl true
  def handle_disconnect(_conn, state = %Self{}) do
    send(state.receiver, :disconnect)
    {:ok, %Self{state | receiver: nil}}
  end

  @impl true
  def handle_frame({:text, msg}, state = %Self{}) when state.receiver == nil do
    queue = :queue.in(msg, state.queue)
    {:ok, %Self{state | queue: queue}}
  end

  @impl true
  def handle_frame({:text, msg}, state = %Self{}) do
    send(state.receiver, msg)
    {:ok, %Self{state | receiver: nil}}
  end

  defmacrop queue_is_empty(queue) do
    quote do
      unquote(queue) == {[], []}
    end
  end

  @impl true
  def handle_info({:receive, receiver}, state = %Self{}) when queue_is_empty(state.queue) do
    {:ok, %Self{state | receiver: receiver}}
  end

  @impl true
  def handle_info({:receive, receiver}, state = %Self{}) do
    {{:value, msg}, queue} = :queue.out(state.queue)
    send(receiver, msg)
    {:ok, %Self{state | queue: queue}}
  end
end
