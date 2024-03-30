defmodule Client.Application do
  @moduledoc """
  Client application supervisor
  """

  alias Client.WebSocket.Wrapper, as: WebSocketClient

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ws_client_spec(),
    ]
    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def ws_client_spec do
    config = Application.get_env(:client, Client.WebSocket.Wrapper)
    if not Keyword.has_key?(config, :server_url) do
      raise "'server_url' must present in config file"
    end
    heartbeat = Keyword.get(config, :heartbeat, false)
    server_url = Keyword.get(config, :server_url)
    {WebSocketClient, [heartbeat: heartbeat, server_url: server_url]}
  end
end
