defmodule Server.Web.SendEmail.Handler do
  @moduledoc """
  Handler for sending emails
  """
  require Logger
  alias Swoosh.Email
  alias Plug.Conn

  @body_schema Zoi.map(
                 %{
                   token: Zoi.string() |> Zoi.min(5) |> Zoi.required(),
                   sender: Zoi.email() |> Zoi.min(5) |> Zoi.required(),
                   subject: Zoi.string() |> Zoi.min(3) |> Zoi.required(),
                   message: Zoi.string() |> Zoi.min(10) |> Zoi.required()
                 },
                 coerce: true
               )

  def handle_post(conn = %Conn{}) do
    with :ok <- check_content_type(conn, "application/json"),
         {:ok, validated_data} <- Zoi.parse(@body_schema, conn.body_params),
         :ok <- verify_turnstile_token(validated_data),
         :ok <- send_email(validated_data) do
      respond_json(conn, 200, "Ok")
    else
      {:error, :wrong_content_type} -> respond_json(conn, 400, "Bad request")
      {:error, [%Zoi.Error{} | _] = errors} -> respond_json(conn, 422, Jason.encode!(errors))
      :error -> Conn.send_resp(conn, 500, "Internal server error")
    end
  end

  defp check_content_type(conn = %Conn{}, content_type) do
    found_header =
      Stream.filter(conn.req_headers, fn header ->
        header == {"content-type", content_type}
      end)
      |> Enum.take(1)

    case length(found_header) do
      1 -> :ok
      0 -> {:error, :wrong_content_type}
    end
  end

  defp verify_turnstile_token(data) do
    turnstile_verifier = Application.fetch_env!(:server, :turnstile_verifier)

    case turnstile_verifier.verify_token(data.token) do
      {:ok, true} ->
        :ok

      {:ok, false} ->
        {:error, [%Zoi.Error{code: "invalid", path: ["token"]}]}

      {:error, error} ->
        Logger.error("Token verification failed: #{error}")
        :error
    end
  end

  defp send_email(data) do
    email =
      Email.new()
      |> Email.to(Application.fetch_env!(:server, :email_recipient))
      |> Email.from("contact@attiladudas.com")
      |> Email.subject("#{data.subject} - #{data.sender}")
      |> Email.text_body(data.message)

    case Server.Mailer.deliver(email) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Could not send email: #{error}")
        :error
    end
  end

  defp respond_json(conn = %Conn{}, status_code, content) do
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(status_code, content)
  end
end
