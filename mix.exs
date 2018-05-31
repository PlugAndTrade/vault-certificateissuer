defmodule VaultCertificateIssuer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :vault_certificate_issuer,
      version: "0.3.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [
        :afunix,
        :httpoison,
        :jose,
        :poison,
        :timex
      ],
      extra_applications: [:logger],
      mod: {VaultCertificateIssuer, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 1.5", runtime: false},
      {:httpoison, "~> 1.0"},
      {:jose, "~> 1.8"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"},
      {:afunix,  github: "tonyrog/afunix", manager: :rebar},
      {:vault_client, github: "PlugAndTrade/vault-client-elixir", tag: "0.1.0" },
    ]
  end
end
