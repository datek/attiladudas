defmodule Server.Web.FiveInARow.Messages.GameUpdate do
  defstruct cells: nil,
            next_player: "",
            winner: ""
end

defimpl Jason.Encoder, for: Server.Web.FiveInARow.Messages.GameUpdate do
  alias Server.Web.FiveInARow.Messages.GameUpdate

  def encode(value = %GameUpdate{}, opts) do
    cells =
      for {{x, y}, value} <- value.cells, into: %{} do
        {String.to_atom("#{x};#{y}"), value}
      end

    Jason.Encode.map(%{cells: cells, next_player: value.next_player, winner: value.winner}, opts)
  end
end
