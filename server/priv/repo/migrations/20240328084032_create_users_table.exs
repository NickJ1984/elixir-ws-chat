defmodule Server.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :login, :string, size: 100, primary_key: true
      add :password, :string, size: 255, null: false
    end
  end
end
