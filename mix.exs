defmodule VaultCertificateIssuer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :vault_certificate_issuer,
      version: "0.3.7",
      elixir: "~> 1.6.5",
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
        :timex,
        :vault_client,
      ],
      extra_applications: [:logger],
      mod: {VaultCertificateIssuer, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 2.0", runtime: false},
      {:httpoison, "~> 1.3"},
      {:jose, "~> 1.8"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.5"},
      {:afunix,  github: "tonyrog/afunix", manager: :rebar},
      {:vault_client, github: "PlugAndTrade/vault-client-elixir", tag: "0.3.0" },
    ]
  end
end
