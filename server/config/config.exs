import Config

config :server, Server.Repo,
  database: "chat_server_db",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432

config :server, Server.WebSocket.Handler,
  # Maximum frame size in bytes allowed by this Websocket handler.
  # Максимальный размер фрейма в байтах
  max_frame_size: 5_120,
  # Время в миллисекундах в течении которого сервер будет поддерживать соединение
  # с клиентом не получая никаких данных от него.
  idle_timeout: 600_000

config :server,
  ecto_repos: [Server.Repo],
  port: 4_000
