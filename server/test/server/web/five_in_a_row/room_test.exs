defmodule Server.Web.FiveInARow.RoomTest do
  alias Server.Web.FiveInARow.Room
  use ExUnit.Case

  test "Room is being stopped after configured timeout" do
    # given
    timeout = 1
    {:ok, room} = Room.start_link("room1", timeout)

    # when
    Process.sleep(timeout + 10)

    # then
    assert !Process.alive?(room)
  end
end
