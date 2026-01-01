defmodule Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :server,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        server: [
          steps: [:assemble, :tar]
        ]
      ],
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
      {:cors_plug, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.18"},
      {:req, "~> 0.5.16"},
      {:swoosh, "~> 1.19"},
      {:websock_adapter, "~> 0.5.9"},
      {:websockex, "~> 0.4.3"},
      {:zoi, "~> 0.12.0"},
      {:excoveralls, "~> 0.18.5", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
