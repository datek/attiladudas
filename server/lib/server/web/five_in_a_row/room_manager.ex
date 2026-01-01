defmodule Server.Web.FiveInARow.RoomManager do
  @moduledoc """
  The global room manager process. Responsible for providing rooms.
  """
  alias __MODULE__, as: Self
  alias Server.Web.FiveInARow.Room

  def start_link() do
    DynamicSupervisor.start_link(
      name: Self,
      strategy: :one_for_one
    )
  end

  def child_spec(_arg) do
    %{
      id: Self,
      start: {Self, :start_link, []},
      type: :supervisor
    }
  end

  def room_process(room_name) do
    Room.where_is(room_name) || new_process(room_name)
  end

  defp new_process(room_name) do
    {:ok, pid} = DynamicSupervisor.start_child(Self, Room.child_spec(room_name))
    pid
  end
end
