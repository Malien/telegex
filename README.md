# Telegex

The new Telegram Bot API client features a unique and perfect implementation approach!

_😋 Three years ago I created this project, and three years later I redesigned it._

## Configuration

Add bot token to the secret configuration file, like this:

```elixir
config :telegex, token: "<BOT_TOKEN>"
```

Specify the adapter for the HTTP client in the public configuration file:

```elixir
config :telegex, Telegex.Caller, adapter: Telegex.Caller.ReqAdapter
```

You can also choose `HTTPoison` as the client.

Pass options to the adapter, such as timeout:

```elixir
config :telegex, Telegex.Caller, adapter: Telegex.Caller.ReqAdapter,
  options: [connect_options: [timeout: 5 * 1000]]
```

If using HTTPoison, set the timeout this way:

```elixir

config :telegex, Telegex.Caller, adapter: Telegex.Caller.HTTPoisonAdapter,
  options: [recv_timeout: 5 * 1000]
```

**Note: You need to manually add adapter-related libraries to the `deps`:**

- [`req`](https://hex.pm/packages/req): `ReqAdapter`
- [`httpoison`](https://hex.pm/packages/httpoison): `HTTPoisonAdapter`

Don't have a client library you use? Tell me in issues!
