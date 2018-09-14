use Mix.Config

config :logger, :console,
  format: "$date $time $metadata[$level] $levelpad$message\n"
