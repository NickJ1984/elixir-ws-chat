defmodule Server.Application do
  @moduledoc """
  Server application supervisor
  """

  use Application

  @sup Server.Supervisor

  @impl true
  def start(_type, _args) do
    children = [
      Server.Repo,
      Server.Registry,
      cowboy_spec(),
    ]
    Supervisor.start_link(children, [strategy: :one_for_all, name: @sup])
  end

  defp cowboy_spec do
    port = Application.get_env(:server, :port, 4_000)
    dispatch = [
      {
        :_,
        [
          {"/chat", Server.WebSocket.Handler, []},
          {:_, Plug.Cowboy.Handler, {Server.Router, []}}
        ]
      }
    ]
    {
      Plug.Cowboy,
      scheme: :http,
      plug: Server.Router,
      port: port,
      dispatch: dispatch
    }
  end
end
