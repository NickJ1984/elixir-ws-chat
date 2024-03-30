defmodule Client.WebSocket.Client do
  @moduledoc """
  Websockex client
  """

  use WebSockex

  @doc """
  Starts websockex process.

  ## Options

    * `:url` - (required) `binary`, server chat url.

    * `:headers` - (required) `[{binary, binary}]`, extra headers for auth must be passed "user-login", "user-password".

    * `:parent_pid` - (optional) `pid`, parent process pid for sending extra data.

  ## Return values

  Return values described in websockex library docs, please follow the link:
  https://hexdocs.pm/websockex/WebSockex.html#start_link/4
  """
  @spec start_link(Keyword.t) :: {:ok, pid} | {:error, term}
  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    headers = Keyword.fetch!(opts, :headers)
    state = %{
      parent: Keyword.get(opts, :parent_pid),
    }
    opts = [
      extra_headers: headers,
      name: __MODULE__,
    ]
    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  @impl true
  def handle_frame({:text, text}, st) do
    IO.puts(text)
    {:ok, st}
  end
  def handle_frame({:binary, "$get-idle-timeout " <> idle_timeout}, st) do
    send_parent({:idle_timeout, idle_timeout, self()}, st)
    {:ok, st}
  end
  def handle_frame({:binary, "$auth-ok"}, st) do
    send_parent({:authorized, self()}, st)
    {:ok, st}
  end

  @impl true
  def handle_cast({:send_text, text}, state) do
    {:reply, {:text, text}, state}
  end
  def handle_cast(:ping, state) do
    {:reply, :ping, state}
  end
  def handle_cast(:get_idle_timeout, state) do
    {:reply, {:binary, "$get-idle-timeout"}, state}
  end
  def handle_cast(:disconnect, state) do
    {:close, {1000, "disconnect_by_client"}, state}
  end

  @impl true
  def terminate({:local, 1000, "disconnect_by_client"}, st) do
    send_parent({:disconnected, self()}, st)
    {:ok, st}
  end
  def terminate(_reason, state) do
    {:ok, state}
  end

  defp send_parent(payload, %{parent: parent}) when is_pid(parent) do
    Process.send(parent, payload, [])
  end
  defp send_parent(_payload, _st), do: :ok
end
