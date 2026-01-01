defmodule Server.Web.Router do
  use Plug.Router

  plug Plug.Logger, log: :info

  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason,
    pass: ["application/json"]

  plug CORSPlug
  plug :match
  plug :dispatch

  get "/ws/five-in-a-row/" do
    Server.Web.FiveInARow.Handler.handle_get(conn)
  end

  post "/send-email/" do
    Server.Web.SendEmail.Handler.handle_post(conn)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  def child_spec(_) do
    Bandit.child_spec(
      plug: __MODULE__,
      scheme: :http,
      ip: Application.fetch_env!(:server, :http_host),
      port: Application.fetch_env!(:server, :http_port)
    )
  end
end
