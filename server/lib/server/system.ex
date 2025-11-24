defmodule Server.System do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    Supervisor.init(
      [
        Server.Web.FiveInARow.RoomManager,
        Server.Web.Router
      ],
      strategy: :one_for_one
    )
  end
end
