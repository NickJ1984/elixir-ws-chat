import Config

config :client, Client.WebSocket.Wrapper,
  server_url: "ws://localhost:4000/chat",
  # default heartbeat value
  heartbeat: true
