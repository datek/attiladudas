defmodule Server.Web.FiveInARow.Room do
  @moduledoc """
  Room process with two players. Coordinates the game.
  """
  use GenServer

  require Logger
  alias __MODULE__, as: Self
  alias Server.Web.FiveInARow.Player
  alias Server.FiveInARow.Game

  defstruct players: [],
            game: nil

  def join(pid, player_name) do
    GenServer.call(pid, {:join, player_name})
  end

  def pick_side(pid, side) when side in [:X, :O] do
    GenServer.call(pid, {:pick_side, side})
  end

  def take_turn(pid, position) do
    GenServer.call(pid, {:take_turn, position})
  end

  def send_message(pid, message) do
    GenServer.cast(pid, {:send_message, self(), message})
  end

  def start_link(name, timeout \\ 120_000) when is_binary(name) do
    GenServer.start_link(
      Self,
      timeout,
      name: {:global, {Self, name}}
    )
  end

  # only for testing purposes
  def start_link(name, timeout, game = %Game{}) when is_binary(name) do
    GenServer.start_link(
      Self,
      {timeout, game},
      name: {:global, {Self, name}}
    )
  end

  def child_spec(name) do
    %{
      id: Self,
      start: {Self, :start_link, [name]},
      restart: :temporary
    }
  end

  @impl true
  def init({timeout, game = %Game{}}) do
    {:ok, %Self{game: game}, timeout}
  end

  @impl true
  def init(timeout) do
    {:ok, %Self{game: Game.new(11)}, timeout}
  end

  def where_is(room_name) do
    case :global.whereis_name({Self, room_name}) do
      :undefined -> nil
      pid -> pid
    end
  end

  @impl true
  def handle_call({:join, name}, {pid, _}, room = %Self{players: []}) do
    player = %Player{name: name, pid: pid}
    Process.monitor(pid)
    Logger.info("#{player.name} joined #{inspect(self())} from #{inspect(pid)}")
    {:reply, :ok, %Self{room | players: [player]}}
  end

  @impl true
  def handle_call({:join, name}, {pid, _}, room = %Self{players: [player = %Player{}]})
      when player.pid == pid or player.name == name do
    {:reply, {:error, "player_already_joined"}, room}
  end

  @impl true
  def handle_call({:join, name}, {pid, _}, room = %Self{players: [player = %Player{}]}) do
    side =
      case player.side do
        nil -> nil
        :X -> :O
        :O -> :X
      end

    new_player = %Player{name: name, pid: pid, side: side}

    notify_current_state = fn ->
      Process.sleep(10)
      send(pid, {:pick_side, side})
      Process.sleep(10)
      next_player = if room.game.next_player == side, do: name, else: player.name
      update_msg = {room.game.cells, next_player, room.game.winner}
      send(pid, {:game_update, update_msg})
    end

    if side != nil do
      Process.spawn(notify_current_state, [:link])
    end

    Process.monitor(pid)

    send(player.pid, {:join, name})
    Logger.info("#{player.name} joined #{inspect(self())} from #{inspect(pid)}")
    {:reply, :ok, %Self{room | players: [new_player | room.players]}}
  end

  @impl true
  def handle_call({:join, _}, _, room = %Self{players: [%Player{}, %Player{}]}) do
    {:reply, {:error, "room_is_full"}, room}
  end

  @impl true
  def handle_call(
        {:pick_side, side},
        {pid, _},
        room = %Self{players: [%Player{side: nil}, _], game: %Game{}}
      ) do
    this_player =
      %Player{} =
      Enum.filter(room.players, fn player -> player.pid == pid end)
      |> List.first()

    this_player = %Player{this_player | side: side}
    other_player_side = if side == :X, do: :O, else: :X

    other_player =
      %Player{} =
      Enum.filter(room.players, fn player -> player.pid != pid end)
      |> List.first()

    other_player = %Player{other_player | side: other_player_side}
    next_player = if side == :X, do: this_player.name, else: other_player.name
    room = %Self{room | players: [this_player, other_player]}
    Logger.info("#{this_player.name} picked #{side}")
    send(other_player.pid, {:pick_side, other_player_side})
    reply_msg = {room.game.cells, next_player, room.game.winner}
    send(other_player.pid, {:game_update, reply_msg})
    {:reply, {:ok, reply_msg}, room}
  end

  @impl true
  def handle_call({:pick_side, _}, _from, room = %Self{players: [%Player{}]}) do
    {:reply, {:error, "only_one_player_in_room"}, room}
  end

  @impl true
  def handle_call({:pick_side, _}, _from, room) do
    {:reply, {:error, "side_already_decided"}, room}
  end

  @impl true
  def handle_call({:take_turn, _}, _from, room = %Self{game: %Game{winner: winner}})
      when winner != nil do
    {:reply, {:error, "game_ended"}, room}
  end

  @impl true
  def handle_call({:take_turn, _}, _from, room = %Self{players: [%Player{side: nil}]}) do
    {:reply, {:error, "side_not_picked"}, room}
  end

  @impl true
  def handle_call({:take_turn, _}, _from, room = %Self{players: [%Player{side: nil}, _]}) do
    {:reply, {:error, "side_not_picked"}, room}
  end

  @impl true
  def handle_call({:take_turn, position}, {pid, _}, room = %Self{game: %Game{}}) do
    other_player =
      %Player{side: other_player_side} =
      Enum.filter(room.players, fn player -> player.pid != pid end)
      |> List.first()

    case room.game.next_player do
      ^other_player_side ->
        {:reply, {:error, "not_your_turn"}, room}

      _ ->
        Logger.info("#{inspect(pid)} took turn")
        game = Game.take_turn(room.game, position)
        if game.winner != nil, do: Logger.info("#{inspect(pid)} won the game")
        reply_msg = {game.cells, other_player.name, game.winner}
        send(other_player.pid, {:game_update, reply_msg})
        {:reply, {:ok, reply_msg}, %Self{room | game: game}}
    end
  end

  @impl true
  def handle_cast({:send_message, from, message}, room = %Self{players: [%Player{}, %Player{}]}) do
    target_player =
      %Player{} =
      Enum.filter(room.players, fn player -> player.pid != from end)
      |> List.first()

    send(target_player.pid, {:send_message, message})
    {:noreply, room}
  end

  @impl true
  def handle_cast({:send_message, _, _}, room = %Self{}) do
    {:noreply, room}
  end

  @impl true
  def handle_info(
        {:DOWN, _, :process, pid, _},
        room = %Self{players: [%Player{pid: player_pid, name: name}]}
      )
      when pid == player_pid do
    Logger.info("#{name} left #{inspect(self())} from #{inspect(pid)}")
    Logger.info("#{inspect(self())} is stopping")
    {:stop, :normal, room}
  end

  @impl true
  def handle_info(
        {:DOWN, _, :process, pid, _},
        room = %Self{players: [%Player{}, %Player{}]}
      ) do
    players = Enum.filter(room.players, fn player -> player.pid != pid end)
    other_player = %Player{} = List.first(players)

    player =
      %Player{} =
      Enum.filter(room.players, fn player -> player.pid == pid end)
      |> List.first()

    send(other_player.pid, {:leave, other_player.name})
    Logger.info("#{player.name} left #{inspect(self())} from #{inspect(pid)}")
    {:noreply, %Self{room | players: players}}
  end

  @impl true
  def handle_info(:timeout, room = %Self{}) do
    {:stop, :normal, room}
  end
end
