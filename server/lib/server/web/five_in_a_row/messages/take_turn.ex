defmodule Server.Web.FiveInARow.Messages.TakeTurn do
  @derive Jason.Encoder

  defstruct x: 0,
            y: 0
end
