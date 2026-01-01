defmodule Server.Web.FiveInARow.Messages.TakeTurn do
  @moduledoc """
  Take turn message
  """
  @derive Jason.Encoder

  defstruct x: 0,
            y: 0
end
