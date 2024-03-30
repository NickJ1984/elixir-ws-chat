defmodule Server do
  @moduledoc """
  Основной модуль для взаимодействия с сервером.
  """

  alias Server.Registry
  alias Server.Schema.User

  @doc """
  Создаёт пользователя по указанным логину и паролю.

  ### Аргументы

    * `login` - `binary`, логин пользователя, должен быть больше 0 и менее или равен 100 символам по длине.

    * `password` - `binary`, пароль пользователя, должен быть больше 0 и менее или равен 255 символам по длине.

  ### Возвращаемые значения

    * `{:ok, User.t}` - возвращает структуру созданного пользователя.


    * `{:error, [{field, {description, extra}}]}` - возвращает описание ошибки из за которой не произошла запись
      в базу:

      # `field` - atom, поле в котором возникла ошибка.

      # `description` - binary, краткое описание ошибки.

      # `extra` - Keyword.t, дополнительные данные об ошибке.
  """
  @spec create_user(User.login, User.password) :: User.create_response
  def create_user(login, password) do
    User.create(login, password)
  end

  @doc """
  Возвращает все записи пользователей хранящиеся в БД.
  """
  @spec users() :: [User.t]
  def users, do: User.list()

  @doc """
  Возвращает логины пользователей подключённых в данный момент к серверу.
  """
  @spec users_online() :: [User.login]
  def users_online, do: Registry.list_names()
end
