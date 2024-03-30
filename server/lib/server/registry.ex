defmodule Server.Registry do
  @moduledoc """
  Registry that stores uniq names and pids for client connections
  """

  @spec child_spec(any) :: map
  def child_spec(_arg) do
    %{
      id: __MODULE__,
      restart: :permanent,
      start: {__MODULE__, :start_link, []},
    }
  end

  @spec start_link() :: {:ok, pid} | {:error, any}
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  @spec register(binary) :: :ok | {:error, :already_registered}
  def register(name) do
    case Registry.register(__MODULE__, name, nil) do
      {:ok, _} -> :ok
      _ -> {:error, :already_registered}
    end
  end

  @spec list_pids() :: [pid]
  @spec list_pids(pid | nil) :: [pid]
  def list_pids(exclude_pid \\ nil) do
    match_condition =
      if is_pid(exclude_pid) do
        [{:"=/=", :"$2", exclude_pid}]
      else
        []
      end
    Registry.select(__MODULE__, [{{:_, :"$2", :_}, match_condition, [:"$2"]}])
  end

  @spec list_names() :: [binary]
  def list_names do
    Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @spec exist?(binary) :: boolean
  def exist?(name) do
    match?([{_pid, nil}], Registry.lookup(__MODULE__, name))
  end
end
