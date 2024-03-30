defmodule Client do
  @moduledoc """
  Основной модуль для взаимодействия с клиентом, содержит следующие функции:

  ## connect/2

  Установление соединения и авторизация с чатом сервера. `Url` чата можно задать
  через конфигурационный файл (ключ `server_url`), значение по умолчанию: "ws://localhost:4000/chat".

  ### Аргументы

    * `login` - `binary`, логин пользователя для авторизации на сервере, пустая строка не принимается.

    * `password` - `binary`, пароль пользователя для авторизации на сервере, пустая строка не принимается.

  ### Возвращаемые значения

  Смотрите документацию функции в модуле обертки клиента `Client.WebSocket.Wrapper`

  ### disconnect/0

  Разрывает соединение с сервером, для повторного соединения необходимо использовать `connect/2`.

  ### Возвращаемые значения

  Смотрите документацию функции в модуле обертки клиента `Client.WebSocket.Wrapper`

  ### send_message/1

  Отправляет сообщение на сервер.

  ### Аргументы

    * `text` - `binary`, текстовое сообщение

  ### Возвращаемые значения

  Смотрите документацию функции в модуле обертки клиента `Client.WebSocket.Wrapper`

  ### set_heartbeat/0

  Включает "heartbeat" фреймы для текущего соединения, данное действие позволяет поддерживать
  соединение с сервером. Данная механика включена по умолчанию для всех соединений, отключить её
  можно в конфигурационном файле выставив `false` ключу `heartbeat`.

  ### Возвращаемые значения

  Смотрите документацию функции в модуле обертки клиента `Client.WebSocket.Wrapper`

  ### unset_heartbeat/0

  Выключает "heartbeat" фреймы для текущего соединения, соединение не будет поддерживаься постоянно
  и в случае простоя будет отключено по таймауту заданному на сервере. Имейте ввиду что при переподключении
  механизм будет в состоянии указанном в настройках конфигурационного файлу

  ### Возвращаемые значения

  Смотрите документацию функции в модуле обертки клиента `Client.WebSocket.Wrapper`
  """

  alias Client.WebSocket.Wrapper

  defdelegate connect(login, password), to: Wrapper

  defdelegate disconnect(), to: Wrapper

  defdelegate send_message(text), to: Wrapper

  defdelegate set_heartbeat(), to: Wrapper

  defdelegate unset_heartbeat(), to: Wrapper
end