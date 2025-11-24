defmodule Server.Web.FiveInARow.Messages.Join do
  defstruct room: "",
            player: ""
end

defimpl Jason.Encoder, for: Server.Web.FiveInARow.Messages.Join do
  alias Server.Web.FiveInARow.Messages.Join

  def encode(message = %Join{}, opts) do
    fields =
      case message.room do
        "" -> [:player]
        _ -> [:player, :room]
      end

    Map.take(message, fields)
    |> Jason.Encode.map(opts)
  end
end
