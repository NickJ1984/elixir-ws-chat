# Задание

Написать консольный чат из двух компонентов: сервер и клиент. Клиенты соединяются
с сервером по TCP и держат постоянное соединение. В реализации использовать генсервер и супервизор.

## Требования к серверу

  * Получает и рассылает сообщения от клиентов. Рассылка должна исключать отправителя.

  * При подключении клиента проверяет наличие пользователя, правильность пароля и единственность
    подключения, в случае отказа возвращает два типа ошибки: auth_error (не найден пользовать
    или не подходит пароль) и always_connection (для данного пользователя уже есть активное соединение).

  * Через консоль позволяет добавлять пользователей с паролем (без какой либо крипты, защищать ничего не нужно).

  * Падение обработки входящего запроса не должно аффектить на работоспособность сервера
    и рвать соединения других клиентов.

## Требования к клиенту

  * Поддерживает подключение к серверу с указанием имени и пароля.
  * Позволяет отсылать сообщения.
  * Печатает сообщения других пользователей с их именем.

# Зависимости

  * erlang 25.0
  * elixir 1.14.0-otp-25
  * docker, docker-compose

# Установка зависимостей

## asdf

Для установки определённых версий elixir и erlang лучше воспользоваться менеджером версий `asdf`,
ссылка на его установку:

https://asdf-vm.com/guide/getting-started.html

После установки менеджера необходимо добавить плагины erlang и elixir.

### erlang plugin install

Руководство по установке:

https://github.com/asdf-vm/asdf-erlang

### elixir plugin install

https://github.com/asdf-vm/asdf-elixir

## erlang

`asdf install erlang 25.0`

## elixir

`asdf install elixir 1.14.0-otp-25`

## docker, docker-compose

Необходимо следовать инструкциям по установке специфичным платформе.

https://docs.docker.com/manuals/
