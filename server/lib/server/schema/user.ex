defmodule Server.Schema.User do
  @moduledoc """
  User ecto schema
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Server.Repo

  @type login :: binary
  @type password :: binary

  @type t :: %__MODULE__{
    login: login | nil,
    password: password | nil,
  }

  @type create_response :: {:ok, t} | {:error, [{atom, {binary, Keyword.t}}]}

  @login_max_length 100
  @password_max_length 255

  @foreign_key_type :binary_id
  @primary_key false

  schema "users" do
    field :login, :string, primary_key: true
    field :password, :string
  end

  @required_fields ~w[login password]a

  @spec changeset(map) :: Ecto.Changeset.t
  @spec changeset(t | Ecto.Changeset.t, map) :: Ecto.Changeset.t
  def changeset(user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_length(:login, min: 1, max: @login_max_length)
    |> validate_length(:password, min: 1, max: @password_max_length)
    |> unique_constraint(:login, name: "users_pkey")
  end

  @spec validate_login(login) :: :ok | :error
  def validate_login(login), do: validate_binary_length(login, @login_max_length)

  @spec validate_password(password) :: :ok | :error
  def validate_password(password), do: validate_binary_length(password, @password_max_length)

  @spec create(login, password) :: create_response
  def create(login, password) do
    %{login: login, password: password}
    |> changeset()
    |> Repo.insert()
    |> case do
      {:error, %{errors: errors}} -> {:error, errors}
      resp -> resp
    end
  end

  @spec delete(login) :: {:ok, t} | {:error, :not_found} | {:error, Ecto.Changeset.t}
  def delete(login) do
    with {:ok, user} <- get(login) do
      Repo.delete(user)
    end
  end

  @spec get(login) :: {:ok, t} | {:error, :not_found}
  def get(login) when is_binary(login) do
    case Repo.get_by(__MODULE__, login: login) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
  def get(_login), do: {:error, :not_found}

  @spec list() :: [t]
  def list, do: Repo.all(__MODULE__)

  @spec validate_credentials(login, password) :: :ok | {:error, :auth}
  def validate_credentials(login, password) do
    with :ok <- validate_login(login),
         :ok <- validate_password(password),
         query = (from u in __MODULE__, where: u.login == ^login and u.password == ^password),
         true <- Repo.exists?(query) do
      :ok
    else
      _ -> {:error, :auth}
    end
  end

  defp validate_binary_length("", _max), do: :error
  defp validate_binary_length(bin, max) when is_binary(bin) do
    if String.length(bin) > max do
      :error
    else
      :ok
    end
  end
  defp validate_binary_length(_bin, _max), do: :error
end
