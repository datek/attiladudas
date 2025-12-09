defmodule Server.Web.SendEmail.Handler do
  require Logger
  alias Swoosh.Email
  alias Server.Web.SendEmail.BodySchema
  alias Plug.Conn

  def handle_post(conn = %Conn{}) do
    check_content_type(conn, "application/json")
  end

  defp check_content_type(conn = %Conn{}, content_type) do
    found_header =
      Stream.filter(conn.req_headers, fn header ->
        header == {"content-type", content_type}
      end)
      |> Enum.take(1)

    {next_step, conn, params} =
      case length(found_header) do
        1 -> {&parse_request/2, conn, nil}
        0 -> {&respond/2, conn, {400, "Bad request"}}
      end

    next_step.(conn, params)
  end

  defp parse_request(conn = %Conn{}, _) do
    {:ok, _, conn} = Conn.read_body(conn)

    {next_step, params} =
      case BodySchema.parse(conn.body_params) do
        {:ok, data = %BodySchema{}} ->
          {&verify_turnstile_token/2, data}

        {:error, errors} ->
          serialized = Jason.encode!(errors)
          {&respond/2, {422, serialized}}
      end

    next_step.(conn, params)
  end

  defp verify_turnstile_token(conn = %Conn{}, data = %BodySchema{}) do
    turnstile_verifier = Application.fetch_env!(:server, :turnstile_verifier)

    {next_step, params} =
      case turnstile_verifier.verify_token(data.token) do
        {:ok, true} ->
          {&send_email/2, data}

        {:ok, false} ->
          errors = [%Zoi.Error{code: "invalid", path: ["token"]}]
          serialized_errors = Jason.encode!(errors)
          {&respond/2, {422, serialized_errors}}

        {:error, error} ->
          Logger.error("Token verification failed: #{error}", error: error)
          {&respond/2, {500, "Internal server error"}}
      end

    next_step.(conn, params)
  end

  defp send_email(conn = %Conn{}, data = %BodySchema{}) do
    email =
      Email.new()
      |> Email.to(Application.fetch_env!(:server, :email_recipient))
      |> Email.from("contact@attiladudas.com")
      |> Email.subject(data.subject)
      |> Email.text_body(data.message)

    {status, text} =
      case Server.Mailer.deliver(email) do
        {:ok, _} ->
          {200, "Ok"}

        {:error, error} ->
          Logger.error("Could not send email: #{error}", error: error)
          {500, "Internal server error"}
      end

    respond(conn, {status, text})
  end

  defp respond(conn = %Conn{}, {status_code, content}) do
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(status_code, content)
    |> Conn.halt()
  end
end
