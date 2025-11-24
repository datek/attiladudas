import Config

http_host = System.get_env("SERVER_HTTP_HOST", "127.0.0.1")
http_port = System.get_env("SERVER_HTTP_PORT", "8080")
log_level = System.get_env("SERVER_LOG_LEVEL", "info")

config :server,
  http_port: String.to_integer(http_port),
  http_host: http_host
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> Enum.to_list()
    |> List.to_tuple()

config :logger,
  level: String.to_atom(log_level)
