defmodule Telegex.MethodTest do
  use ExUnit.Case

  # Test method invokations end-to-end
  # Testing things other than get_me with the real Telegram servers is tricky,
  # since we'd have to have at least two accounts to test sending messages, 
  # checking for updates, etc.
  test "get_me" do
    Application.put_env(:telegex, :caller_adapter, Finch)

    {:ok, user} = Telegex.get_me()
    assert match?(%Telegex.Type.User{is_bot: true}, user)
    assert is_integer(user.id)
    assert is_binary(user.first_name)
    assert is_binary(user.username)
  end
end
