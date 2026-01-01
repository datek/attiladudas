defmodule Server.Web.TurnstileVerifier do
  @moduledoc """
  Module for verifyting the cludflare turnstile token
  """
  require Logger
  @req Req.new(url: "https://challenges.cloudflare.com/turnstile/v0/siteverify")

  @spec verify_token(binary()) :: {:ok, true | false} | {:error, binary()}
  def verify_token(token) do
    case Req.post(
           @req,
           json: %{
             secret: Application.fetch_env!(:server, :turnstile_secret),
             response: token
           }
         ) do
      {:ok, resp = %Req.Response{}} ->
        {:ok, resp.status == 200}

      {:error, error} ->
        {:error, "#{error}"}
    end
  end
end
