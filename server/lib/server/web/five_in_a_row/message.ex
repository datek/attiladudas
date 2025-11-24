defmodule Server.Web.FiveInARow.Message do
  alias Server.Web.FiveInARow.Messages.GameUpdate
  alias Server.Web.FiveInARow.Messages.TakeTurn
  alias Server.Web.FiveInARow.Message
  alias Server.Web.FiveInARow.Messages.Join

  defstruct type: "",
            data: nil

  @type_map %{
    "JOIN" => Join,
    "TAKE_TURN" => TakeTurn,
    "GAME_UPDATE" => GameUpdate
  }

  def encode!(msg = %Message{}) do
    Jason.encode!(msg)
  end

  def parse(raw) do
    case Jason.decode(raw, keys: :atoms!) do
      {:ok, %{type: type, data: data}} ->
        case type do
          type when type in ["BAD_MESSAGE", "LEAVE", "SEND_MESSAGE"] ->
            %Message{type: type, data: data}

          "PICK_SIDE" when data in ["X", "O"] ->
            %Message{type: type, data: String.to_atom(data)}

          _ ->
            module = Map.get(@type_map, type)

            case module do
              nil -> :error
              _ -> %Message{type: type, data: struct(module, data)}
            end
        end

      {:ok, %{type: type}} ->
        %Message{type: type}

      _ ->
        :error
    end
  end

  def new_ok() do
    %Message{type: "OK"}
    |> Message.encode!()
  end

  def new_error(code) do
    %Message{type: "BAD_MESSAGE", data: code}
    |> Message.encode!()
  end

  def new_join(room, player) do
    %Message{type: "JOIN", data: %Join{room: room, player: player}}
    |> Message.encode!()
  end

  def new_pick_side(side) do
    %Message{type: "PICK_SIDE", data: side}
    |> Message.encode!()
  end

  def new_take_turn({x, y}) do
    %Message{type: "TAKE_TURN", data: %TakeTurn{x: x, y: y}}
    |> Message.encode!()
  end

  def new_leave(player_name) do
    %Message{type: "LEAVE", data: player_name}
    |> Message.encode!()
  end

  def new_game_update(cells, next_player, winner) do
    %Message{
      type: "GAME_UPDATE",
      data: %GameUpdate{cells: cells, next_player: next_player, winner: winner}
    }
    |> Message.encode!()
  end

  def new_send_message(message) do
    %Message{type: "SEND_MESSAGE", data: message}
    |> Message.encode!()
  end
end

defimpl Jason.Encoder, for: Server.Web.FiveInARow.Message do
  alias Server.Web.FiveInARow.Message

  def encode(message = %Message{}, opts) do
    fields =
      case message.data do
        nil -> [:type]
        _ -> [:type, :data]
      end

    Map.take(message, fields)
    |> Jason.Encode.map(opts)
  end
end
