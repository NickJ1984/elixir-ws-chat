defmodule Client.WebSocket.Wrapper do
  @moduledoc """
  Websockex client wrapper
  """

  alias Client.WebSocket.Client, as: WS

  require Logger

  use GenServer

  defguardp non_empty_binary(value) when is_binary(value) and byte_size(value) > 0

  @doc """
  Starts wrapper process.

  ## Options

    * `:server_url` - (required) `binary`, server chat url

    * `:heartbeat` - (optional) `boolean`, if set to `true` enables heartbeat frames
      to server for keeping alive connection (default: `false`)
  """
  @spec start_link(Keyword.t) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Connects to the chat server

  ## Arguments

    * `login` - user login, string must be more than 0 characters length.

    * `password` - user password, string must be more than 0 characters length.

  ## Return values

    * `:ok` - Connection with server was successfully established. Keep in mind that auth
      procedure follows right after that in async mode, logger message will informs you about result.

    * `{:error, :wait_for_auth}` - Server connection was successfully established, and now client waits
      for server auth response.

    * `{:error, :already_connected}` - You're already connected and authorized by the server.

    * `{:error, :bad_argument}` - one or both arguments don't meet the conditions.

    Other errors returns from `Client.WebSocket.Client.start_link/1` please refer to its documentation.
  """
  @spec connect(binary, binary) :: :ok | {:error, :wait_for_auth} | {:error, :already_connected} | {:error, :bad_argument} | {:error, any()}
  def connect(login, password) when non_empty_binary(login) and non_empty_binary(password) do
    GenServer.call(__MODULE__, {:connect, login, password})
  end
  def connect(_login, _password), do: {:error, :bad_argument}

  @doc """
  Disconnects from the server.
  """
  @spec disconnect() :: :ok
  def disconnect do
    GenServer.cast(__MODULE__, :disconnect)
  end

  @doc """
  Sends message to the server.

  ## Arguments

    * `text` - user message, string must be more than 0 characters length.

  ## Return values

    * `:ok` - This function performs unblocking call so this response means nothing
      except response was sent to the wrapper process.

    * `{:error, :bad_argument}` - argument doesn't meet the conditions.
  """
  @spec send_message(binary) :: :ok | {:error, :bad_argument}
  def send_message(text) when non_empty_binary(text) do
    GenServer.cast(__MODULE__, {:send_text, text})
  end
  def send_message(_text), do: {:error, :bad_argument}

  @doc """
  Turns on heartbeat frames for this connection, do nothing if it's already turned on.

  ## Return values

    * `{:ok, :set}` - heartbeat frames were turned on.

    * `{:ok, :pending}` - client receiving neccessary data from the server to
      turn on heartbeat frames, you will be informed through the log messages about the result
      or you can execute this function later again to specify result.

    * `{:error, :no_connection}` - there is no active connection at this moment.
  """
  @spec set_heartbeat() :: {:ok, :set} | {:ok, :pending} | {:error, :no_connection}
  def set_heartbeat do
    GenServer.call(__MODULE__, {:set_heartbeat, true})
  end

  @doc """
  Turns off heartbeat frames for this connection, do nothing if it's already turned off.

  ## Return values

    * `:ok` - heartbeat frames were turned off.

    * `{:error, :busy}` - client in process of turning on heartbeat frames at the moment,
      you need to execute this function a bit later.

    * `{:error, :no_connection}` - there is no active connection at this moment.
  """
  @spec unset_heartbeat() :: :ok | {:error, :busy} | {:error, :no_connection}
  def unset_heartbeat do
    GenServer.call(__MODULE__, {:set_heartbeat, false})
  end

  @impl true
  def init(opts) do
    if not Keyword.has_key?(opts, :server_url) do
      raise "'server_url' key not found"
    end
    Process.flag(:trap_exit, true)
    heartbeat = %{
      global: Keyword.get(opts, :heartbeat, false),
      ref: nil,
      repeat_time: nil,
      status: nil,
    }
    state = %{
      client: nil,
      headers: nil,
      heartbeat: heartbeat,
      status: nil,
      url: Keyword.get(opts, :server_url),
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:connect, login, password}, _from, %{status: nil} = st) do
    headers = [
      {"user-login", login},
      {"user-password", password},
    ]
    opts = [
      headers: headers,
      parent_pid: self(),
      url: st.url,
    ]
    case WS.start_link(opts) do
      {:ok, pid} -> {:reply, :ok, %{st | client: pid, status: :auth}}
      error ->  {:reply, error, st}
    end
  end
  def handle_call({:connect, _login, _password}, _from, %{status: :auth} = st) do
    {:reply, {:error, :wait_for_auth}, st}
  end
  def handle_call({:connect, _login, _password}, _from, st) do
    {:reply, {:error, :already_connected}, st}
  end
  def handle_call({:set_heartbeat, true}, _from, %{status: :ok} = st) do
    {reply, st} = heartbeat(:set, st)
    {:reply, {:ok, reply}, st}
  end
  def handle_call({:set_heartbeat, false}, _from, %{status: :ok} = st) do
    case heartbeat(:unset, st) do
      {:busy, st} -> {:reply, {:error, :busy}, st}
      {reply, st} -> {:reply, reply, st}
    end
  end
  def handle_call({:set_heartbeat, _value}, _from, st) do
    {:reply, {:error, :no_connection}, st}
  end

  @impl true
  def handle_cast({:send_text, text}, %{client: client, status: :ok} = st) do
    WebSockex.cast(client, {:send_text, text})
    {:noreply, st}
  end
  def handle_cast({:send_text, _}, st) do
    {:noreply, st}
  end
  def handle_cast(:disconnect, %{client: client, status: :ok} = st) do
    WebSockex.cast(client, :disconnect)
    {:noreply, st}
  end
  def handle_cast(:disconnect, st) do
    {:noreply, st}
  end

  @impl true
  def handle_info(:send_heartbeat, %{client: client, status: status} = st) when status in ~w[ok auth]a do
    WebSockex.cast(client, :ping)
    {:noreply, set_heartbeat_timer(st)}
  end
  def handle_info(:send_heartbeat, st) do
    {:noreply, clear_heartbeat(st)}
  end
  def handle_info({:idle_timeout, idle_timeout, client}, %{client: client, status: :ok} = st) do
    %{heartbeat: heartbeat} = st
    st =
      with true <- heartbeat.status == :pending,
          {:ok, repeat_time} <- process_heartbeat_repeat_time(idle_timeout) do
        heartbeat = %{heartbeat | repeat_time: repeat_time, status: :set}
        Logger.info("client: heartbeat is set (#{repeat_time}ms)")
        st
        |> Map.put(:heartbeat, heartbeat)
        |> set_heartbeat_timer()
      else
        {:error, :parse} ->
          Logger.error("client: server timeout response couldn't be parsed #{inspect(idle_timeout)}")
          put_in(st, ~w[heartbeat status]a, nil)

        _ ->
          put_in(st, ~w[heartbeat status]a, nil)
      end
    {:noreply, st}
  end
  def handle_info({:authorized, client}, %{client: client, status: :auth} = st) do
    st = if st.heartbeat.global, do: :set |> heartbeat(st) |> elem(1), else: st
    Logger.info("connection: authorized")
    {:noreply, %{st | status: :ok}}
  end
  def handle_info({:disconnected, client}, %{client: client, status: :ok} = st) do
    Logger.error("connection: disconnected")
    {:noreply, clear_state(st)}
  end
  def handle_info({:EXIT, client, message}, %{client: client} = st) do
    process_client_exit_messages(message)
    {:noreply, clear_state(st)}
  end
  def handle_info({:EXIT, _client, :normal}, st) do
    {:noreply, st}
  end

  defp heartbeat(:set, st) do
    case st.heartbeat do
      %{status: :set} ->
        {:set, st}

      %{status: :pending} ->
        {:pending, st}

      %{status: nil, repeat_time: nil} ->
        WebSockex.cast(st.client, :get_idle_timeout)
        {:pending, put_in(st, ~w[heartbeat status]a, :pending)}

      %{status: nil, repeat_time: repeat_time} ->
        Logger.info("client: heartbeat is set (#{repeat_time}ms)")
        WebSockex.cast(st.client, :ping)
        st = st |> put_in(~w[heartbeat status]a, :set) |> set_heartbeat_timer()
        {:set, st}
    end
  end
  defp heartbeat(:unset, st) do
    case st.heartbeat do
      %{status: :set} -> {:ok, clear_heartbeat(st)}
      %{status: :pending} -> {:busy, st}
      _ -> {:ok, clear_heartbeat(st)}
    end
  end

  defp clear_heartbeat(%{heartbeat: heartbeat} = st) do
    if is_reference(heartbeat.ref), do: Process.cancel_timer(heartbeat.ref)
    %{st | heartbeat: %{heartbeat | ref: nil, status: nil}}
  end

  defp clear_state(st) do
    st
    |> clear_heartbeat()
    |> Map.merge(%{client: nil, status: nil})
  end

  defp set_heartbeat_timer(st) do
    %{heartbeat: %{ref: ref, repeat_time: repeat_time}} = st
    if is_reference(ref), do: Process.cancel_timer(ref)
    ref = Process.send_after(self(), :send_heartbeat, repeat_time)
    put_in(st, ~w[heartbeat ref]a, ref)
  end

  defp process_heartbeat_repeat_time(idle_timeout) do
    with {timeout, _} when timeout > 0 <- Integer.parse(idle_timeout),
         timeout when timeout > 0 <- trunc(timeout * 0.9) do
      {:ok, timeout}
    else
      _ -> {:error, :parse}
    end
  end

  defp process_client_exit_messages({:remote, 1008, error}), do: Logger.error("connection: #{error}")
  defp process_client_exit_messages({:remote, :closed}), do: Logger.error("connection: server interrupted connection")
  defp process_client_exit_messages(:normal), do: Logger.error("connection: timed out")
  defp process_client_exit_messages(message) do
    Logger.error("connection: interrupted for an unknown reason: #{inspect(message)}")
  end
end
