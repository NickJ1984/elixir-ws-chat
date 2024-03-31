defmodule Server.DataCase do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Server.Repo

  setup do
    :ok = Sandbox.checkout(Repo)
  end
end
