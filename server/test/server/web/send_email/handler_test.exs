defmodule Server.Web.SendEmail.HandlerTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn
  import Swoosh.TestAssertions

  alias Server.Web.Router

  @path "/send-email/"

  @opts Router.init([])

  defmodule TurnstileVerifier do
    @valid_token "valid_token"
    @error_token "error_token"

    def verify_token(token) do
      case token do
        @valid_token -> {:ok, true}
        @error_token -> {:error, "nuclear_meltdown"}
        _ -> {:ok, false}
      end
    end

    def valid_token(), do: @valid_token
    def error_token(), do: @error_token
  end

  Application.put_env(:server, :turnstile_verifier, TurnstileVerifier)

  test "Sends email" do
    # given
    subject = "Psychohistory"
    sender = "Demerzel@trantor.gov"

    conn =
      conn(
        :post,
        @path,
        Jason.encode!(%{
          token: TurnstileVerifier.valid_token(),
          sender: sender,
          subject: subject,
          message: "You need to start ASAP"
        })
      )
      |> put_req_header("content-type", "application/json")

    # when
    conn = Router.call(conn, @opts)

    # then
    assert conn.state == :sent
    assert conn.status == 200
    assert_email_sent(subject: "#{subject} - #{sender}")
  end

  test "Returns unprocessable entity when turnstile token is invalid" do
    # given
    conn =
      conn(
        :post,
        @path,
        Jason.encode!(%{
          token: "fake-token",
          sender: "Demerzel@trantor.gov",
          subject: "Psychohistory",
          message: "You need to start ASAP"
        })
      )
      |> put_req_header("content-type", "application/json")

    # when
    conn = Router.call(conn, @opts)

    # then
    assert conn.state == :sent
    assert conn.status == 422
  end

  test "Returns internal server error when token verification fails" do
    # given
    conn =
      conn(
        :post,
        @path,
        Jason.encode!(%{
          token: TurnstileVerifier.error_token(),
          sender: "Demerzel@trantor.gov",
          subject: "Psychohistory",
          message: "You need to start ASAP"
        })
      )
      |> put_req_header("content-type", "application/json")

    # when
    conn = Router.call(conn, @opts)

    # then
    assert conn.state == :sent
    assert conn.status == 500
  end

  test "Returns bad request when content type is missing" do
    # given
    conn = conn(:post, @path)

    # when
    conn = Router.call(conn, @opts)

    # then
    assert conn.state == :sent
    assert conn.status == 400
  end

  test "Returns unprocessable entity when token is missing" do
    # given
    conn =
      conn(:post, @path)
      |> put_req_header("content-type", "application/json")

    # when
    conn = Router.call(conn, @opts)

    # then
    assert conn.state == :sent
    assert conn.status == 422
  end
end
