import Config

config :server, Server.Repo,
  database: "test_chat_server_db",
  pool: Ecto.Adapters.SQL.Sandbox
