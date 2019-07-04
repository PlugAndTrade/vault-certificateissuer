defmodule VaultCertificateIssuer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :vault_certificate_issuer,
      version: "0.3.8",
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
      {:poison, "~> 3.1"},
      {:timex, "~> 3.5"},
      {:afunix,  github: "tonyrog/afunix", manager: :rebar},
      {:vault_client, github: "PlugAndTrade/vault-client-elixir", tag: "0.3.0" },
      {:x509, github: "PlugAndTrade/elixir-x509", tag: "0.3.2"}
    ]
  end
end
