defmodule Server.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :server,
    adapter: Ecto.Adapters.Postgres
end
