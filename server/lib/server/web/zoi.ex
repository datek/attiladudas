defimpl Jason.Encoder, for: Zoi.Error do
  def encode(value, opts) do
    Jason.Encode.map(Map.take(value, [:code, :message, :path]), opts)
  end
end
