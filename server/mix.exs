defmodule Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :server,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [
        tool: ExCoveralls,
        export: "cov"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Server.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.18"},
      {:websock_adapter, "~> 0.5.9"},
      {:websockex, "~> 0.4.3"},
      {:excoveralls, "~> 0.18.5", only: :test}
    ]
  end
end
