defmodule Server.Web.SendEmail.BodySchema do
  @moduledoc """
  Zoi request body schema of /send-email/
  """
  @schema Zoi.object(%{
            "token" => Zoi.string() |> Zoi.min(5) |> Zoi.required(),
            "sender" => Zoi.email() |> Zoi.min(5) |> Zoi.required(),
            "subject" => Zoi.string() |> Zoi.min(3) |> Zoi.required(),
            "message" => Zoi.string() |> Zoi.min(10) |> Zoi.required()
          })

  defstruct [:token, :sender, :subject, :message]

  def parse(data = %{}) do
    case Zoi.parse(@schema, data) do
      {:error, _} = err ->
        err

      {:ok, res} ->
        struct_fields = for {k, v} <- res, into: %{}, do: {String.to_atom(k), v}
        {:ok, struct(__MODULE__, struct_fields)}
    end
  end
end
