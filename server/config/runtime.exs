import Config

http_host = System.get_env("SERVER_HTTP_HOST", "127.0.0.1")
http_port = System.get_env("SERVER_HTTP_PORT", "8080")
log_level = System.get_env("SERVER_LOG_LEVEL", "info")
turnstile_secret = System.fetch_env!("SERVER_TURNSTILE_SECRET")
email_recipient = System.fetch_env!("SERVER_EMAIL")

config :server,
  http_port: String.to_integer(http_port),
  http_host:
    http_host
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> Enum.to_list()
    |> List.to_tuple(),
  turnstile_verifier: Server.Web.TurnstileVerifier,
  turnstile_secret: turnstile_secret,
  email_recipient: email_recipient

config :logger,
  level: String.to_atom(log_level)

config :swoosh, :api_client, Swoosh.ApiClient.Req

if Config.config_env() == :test do
  IO.puts("Using test mail adapter")
  config :server, Server.Mailer, adapter: Swoosh.Adapters.Test
else
  mailjet_api_key = System.fetch_env!("SERVER_MAILJET_API_KEY")
  mailjet_secret_key = System.fetch_env!("SERVER_MAILJET_SECRET_KEY")

  config :server, Server.Mailer,
    adapter: Swoosh.Adapters.Mailjet,
    api_key: mailjet_api_key,
    secret: mailjet_secret_key
end
