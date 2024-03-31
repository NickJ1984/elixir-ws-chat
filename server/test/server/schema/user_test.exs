defmodule Server.Schema.UserTest do
  use Server.DataCase, async: false

  alias Server.Schema.User

  describe "validate_login/1" do
    test "returns ok when passes valid string" do
      assert :ok = User.validate_login("user")
      assert :ok = User.validate_login("a")
      long_name = String.duplicate("a", 100)
      assert :ok = User.validate_login(long_name)
    end

    test "returns error when passes empty string" do
      assert :error = User.validate_login("")
    end

    test "returns error when passes string with length more than 100 characters" do
      long_name = String.duplicate("a", 101)
      assert :error = User.validate_login(long_name)
    end

    test "returns error when passes invalid string" do
      assert :error = User.validate_login(<<0xFFFF::16>>)
    end

    test "returns error when passes not a string type" do
      assert :error = User.validate_login(1)
      assert :error = User.validate_login(nil)
      assert :error = User.validate_login({2, 9})
      assert :error = User.validate_login([1, 2, 3])
      assert :error = User.validate_login([1, 2, 3])
    end
  end

  describe "validate_password/1" do
    test "returns ok when passes valid string" do
      assert :ok = User.validate_password("password")
      assert :ok = User.validate_password("a")
      long_name = String.duplicate("a", 100)
      assert :ok = User.validate_password(long_name)
    end

    test "returns error when passes empty string" do
      assert :error = User.validate_password("")
    end

    test "returns error when passes string with length more than 255 characters" do
      long_name = String.duplicate("a", 256)
      assert :error = User.validate_password(long_name)
    end

    test "returns error when passes invalid string" do
      assert :error = User.validate_password(<<0xFFFF::16>>)
    end

    test "returns error when passes not a string type" do
      assert :error = User.validate_password(1)
      assert :error = User.validate_password(nil)
      assert :error = User.validate_password({2, 9})
      assert :error = User.validate_password([1, 2, 3])
      assert :error = User.validate_password([1, 2, 3])
    end
  end

  describe "create/2" do
    test "creates user when valid params passed" do
      login = "foo"
      password = "foo"
      assert {:ok, %User{login: ^login, password: ^password}} = User.create(login, password)
    end

    test "returns error when valid not unique login passed" do
      login = "foo"
      password = "foo"
      assert {:ok, _} = User.create(login, password)
      assert {:error, resp} = User.create(login, password)
      assert {"has already been taken", [_ | _]} = Keyword.fetch!(resp, :login)
    end

    test "returns error when invalid login passed" do
      assert {:error, resp} = User.create(1, "password")
      assert {"is invalid", [_ | _]} = Keyword.fetch!(resp, :login)
    end

    test "returns error when invalid password passed" do
      assert {:error, resp} = User.create("login", 1)
      assert {"is invalid", [_ | _]} = Keyword.fetch!(resp, :password)
    end

    test "returns error when both arguments are invalid" do
      assert {:error, resp} = User.create(1, 2)
      assert {"is invalid", [_ | _]} = Keyword.fetch!(resp, :login)
      assert {"is invalid", [_ | _]} = Keyword.fetch!(resp, :password)
    end
  end

  describe "delete/1" do
    setup :setup_precreated_user

    test "deletes user correctly", %{user: %{login: login}} do
      assert {:ok, %User{login: ^login}} = User.delete(login)
    end

    test "returns error when user not exists", %{user: %{login: login}} do
      assert {:ok, _} = User.delete(login)
      assert {:error, :not_found} = User.delete(login)
    end
  end

  describe "get/1" do
    setup :setup_precreated_user

    test "returns user correctly", %{user: %{login: login}} do
      assert {:ok, %User{login: ^login}} = User.get(login)
      assert {:ok, %User{login: ^login}} = User.get(login)
    end

    test "returns error when user not exists", _ do
      assert {:error, :not_found} = User.get("not-existed-user-login")
    end

    test "returns error if passed invalid attribute", _ do
      assert {:error, :not_found} = User.get(1)
    end
  end

  describe "list/1" do
    test "returns list of existed users" do
      logins = ~w[bar baz foo]
      Enum.each(logins, & {:ok, _} = User.create(&1, "pwd"))
      assert users = [%User{}, %User{}, %User{}] = User.list()
      db_logins = users |> Enum.map(& &1.login) |> Enum.sort()
      assert logins == db_logins
    end

    test "returns empty list if no users" do
      assert [] = User.list()
    end
  end

  describe "validate_credentials/2" do
    setup :setup_precreated_user

    test "returns ok if passed creds are valid", %{user: user} do
      assert :ok = User.validate_credentials(user.login, user.password)
    end

    test "returns error if passed password are invalid", %{user: user} do
      assert {:error, :auth} = User.validate_credentials(user.login, "wrong-password")
    end

    test "returns error if passed login not exists", _ do
      assert {:error, :auth} = User.validate_credentials("john_doe", "wrong-password")
    end

    test "returns error if passed invalid attribute", %{user: user} do
      assert {:error, :auth} = User.validate_credentials(1, user.password)
      assert {:error, :auth} = User.validate_credentials(user.login, 1)
      assert {:error, :auth} = User.validate_credentials(1, 2)
      assert {:error, :auth} = User.validate_credentials("", "")
    end
  end

  defp setup_precreated_user(_ctx) do
    {:ok, user} = User.create("user-1", "user-1-password")
    {:ok, %{user: user}}
  end
end
