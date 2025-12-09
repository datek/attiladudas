defmodule Server.Web.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Server.Web.Router

  @opts Router.init([])

  test "Returns not found when no route matching" do
    # given
    conn = conn(:get, "/fake-endpoint/")

    # when
    conn = Router.call(conn, @opts)

    # then
    assert conn.state == :sent
    assert conn.status == 404
  end
end
