defmodule Telegex.Caller.HTTPoisonAdapter do
  @moduledoc false

  use Telegex.Caller

  @type httposion_resp :: HTTPoison.Response.t()
  @type httposion_err :: %{reason: atom}

  @impl true
  def call(method, params, opts) do
    url = build_url(method)
    json_body = params |> Enum.into(%{}) |> Jason.encode!()

    url |> request(json_body, opts) |> parse_response()
  end

  def request(url, json_body \\ "", _opts \\ []) do
    apply(HTTPoison, :post, [url, json_body, [@json_header], adapter_options()])
  end

  @spec parse_response({:ok, httposion_resp} | {:error, httposion_err}) ::
          {:ok, any} | {:error, Telegex.error()}
  defp parse_response({:ok, %{body: body} = _response}) do
    %{ok: ok, result: result, error_code: error_code, description: description} =
      struct_response(body)

    if ok do
      {:ok, result}
    else
      {:error, %Error{error_code: error_code, description: description}}
    end
  end

  defp parse_response({:error, %{reason: reason} = _error}) do
    {:error, %RequestError{reason: reason}}
  end
end
