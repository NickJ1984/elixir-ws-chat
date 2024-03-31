defmodule Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :server,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Server.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ~w[lib test/support]
  defp elixirc_paths(_), do: ~w[lib]

  defp deps do
    [
      {:plug, "~> 1.15"},
      {:plug_cowboy, "~> 2.7"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "ecto.setup_test_env"],
      "ecto.setup_test_env": &ecto_setup_test_env/1,
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset_test_env": &ecto_reset_test_env/1,
      "ecto.reset": ["ecto.drop", "ecto.setup"],
    ]
  end

  defp ecto_setup_test_env(_) do
    System.cmd("mix", ["ecto.setup"], [env: [{"MIX_ENV", "test"}]])
  end

  defp ecto_reset_test_env(_) do
    System.cmd("mix", ["ecto.reset"], [env: [{"MIX_ENV", "test"}]])
  end
end
