defmodule Telegex.Global do
  @moduledoc """
  Global configuration options.

  Read global configuration options (in contrast to `Telegex.Instance`), where these configuration options
  are directly keyed under `:telegex`.

  ## Option descriptions

    * `api_base_url` - The base URL of the Telegram Bot API. Defaults to `https://api.telegram.org/bot`.
    * `caller_adapter` - The adapter module for making HTTP requests. Defaults to `Finch`.
    * `hook_adapter` - The adapter module for handling webhook requests. Defaults to `Bandit`.
    * `token` - The token of the bot.
  """

  @spec api_base_url :: String.t()
  def api_base_url do
    get_option(:api_base_url, "https://api.telegram.org/bot")
  end

  @spec caller_adapter :: module | {module, keyword}
  def caller_adapter do
    # The default adapter is `Finch`
    get_option(:caller_adapter, Finch)
  end

  @spec hook_adapter :: module
  def hook_adapter do
    # The default adapter is `Bandit`
    get_option(:hook_adapter, Bandit)
  end

  @spec token :: String.t()
  def token do
    get_option(:token)
  end

  defp get_option(key, default \\ nil) do
    Application.get_env(:telegex, key, default)
  end
end
