defmodule Server.WebSocket.Handler do
  @moduledoc false

  alias Server.Registry
  alias Server.Schema.User

  require Logger

  @behaviour :cowboy_websocket

  @default_idle_timeout 60_000
  @default_max_frame_size :infinity

  @impl true
  def init(req, _state) do
    config = Application.get_env(:server, __MODULE__)
    idle_timeout = Keyword.get(config, :idle_timeout, @default_idle_timeout)
    max_frame_size = Keyword.get(config, :max_frame_size, @default_max_frame_size)
    login = get_req_header(req, "user-login")
    password = get_req_header(req, "user-password")
    opts = %{idle_timeout: idle_timeout, max_frame_size: max_frame_size}
    state =
      case User.validate_credentials(login, password) do
        :ok -> %{login: login, idle_timeout: idle_timeout}
        _ -> :error_auth
      end
    {:cowboy_websocket, req, state, opts}
  end

  @impl true
  def websocket_init(:error_auth) do
    {[{:close, 1008, "auth_error"}], :error}
  end
  def websocket_init(state) do
    case Registry.register(state.login) do
      :ok ->
        broadcast("System", "#{state.login} joins the chat")
        {[{:binary, "$auth-ok"}], state}

      _ ->
        {[{:close, 1008, "always_connection"}], :error}
    end
  end

  @impl true
  def websocket_handle({:text, message}, state) do
    broadcast(state.login, message)
    {:ok, state}
  end
  def websocket_handle({:binary, "$get-idle-timeout"}, state) do
    {:reply, {:binary, "$get-idle-timeout #{state.idle_timeout}"}, state}
  end
  def websocket_handle(:ping, state) do
    {:ok, state}
  end
  def websocket_handle(payload, state) do
    Logger.error("#{__MODULE__}: unexpected frame was received: #{inspect(payload)}")
    {:ok, state}
  end

  @impl true
  def websocket_info({:broadcast, message}, state) do
    {:reply, {:text, message}, state}
  end

  @impl true
  def terminate(_reason, _req, :error), do: :ok
  def terminate(_reason, _req, state) do
    broadcast("System", "#{state.login} exits the chat")
    :ok
  end

  defp broadcast(name, message) do
    message = "#{name}: #{message}"
    self()
    |> Registry.list_pids()
    |> Enum.each(& Process.send(&1, {:broadcast, message}, []))
  end

  defp get_req_header(%{headers: headers}, key), do: Map.get(headers, key)
  defp get_req_header(_req, _key), do: nil
end
