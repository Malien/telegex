defmodule Mix.Tasks.Gen.Code do
  @moduledoc false

  require Mix.Generator

  alias Telegex.TypeDefiner.{ArrayType, UnionType}

  @base_module Telegex.Type

  def run(_args) do
    doc_json = Jason.decode!(File.read!("priv/bots_api_doc.json"), keys: :atoms)

    type_args =
      Enum.map(doc_json.types, fn type ->
        %{type | fields: build_fileds_string(type.fields)}
      end)

    union_types =
      Enum.map(doc_json.union_types, fn ut ->
        %{name: ut.name, description: ut.description, types: build_utypes_string(ut.types)}
      end)

    apis =
      Enum.map(doc_json.methods, fn a ->
        %{
          name: a.name,
          description: a.description,
          parameters: build_api_paramaters_string(a.parameters),
          result_type: build_ftype_string(a.result_type)
        }
      end)

    Mix.Generator.copy_template(
      "priv/type_template.ex.eex",
      "lib/telegex/type.ex",
      [union_types: union_types, type_args: type_args],
      force: true
    )

    Mix.Generator.copy_template(
      "priv/api_template.ex.eex",
      "lib/telegex.ex",
      [apis: apis],
      force: true
    )
  end

  def build_utypes_string(types) do
    types
    |> Enum.map(&build_ftype/1)
    |> Macro.escape()
    |> Macro.to_string()
  end

  def build_fileds_string(fields) do
    Enum.map(fields, fn f ->
      %{
        name: String.to_atom(f.name),
        type: build_ftype(f.type),
        optional: f.optional,
        description: f.description
      }
    end)
    |> Macro.escape()
    |> Macro.to_string()
  end

  def build_ftype("String") do
    :string
  end

  def build_ftype("Integer") do
    :integer
  end

  def build_ftype("Float") do
    :float
  end

  def build_ftype("Float number") do
    :float
  end

  def build_ftype("Boolean") do
    :boolean
  end

  def build_ftype("True") do
    :boolean
  end

  def build_ftype(<<"Array of " <> type::binary>>) do
    %ArrayType{elem_type: build_ftype(type)}
  end

  # 部分方法文档的描述处使用了小写开头的 array of
  def build_ftype(<<"array of " <> type::binary>>) do
    %ArrayType{elem_type: build_ftype(type)}
  end

  # 方法 sendMediaGroup 的文档将 `Messages` 引用为 `Message`
  def build_ftype("Messages") do
    build_ftype("Message")
  end

  def build_ftype(other_type) do
    if String.contains?(other_type, " or ") do
      %UnionType{types: build_union_types(other_type)}
    else
      String.to_atom("#{@base_module}.#{other_type}")
    end
  end

  defp build_ftype_string(type) do
    type
    |> build_ftype()
    |> Macro.escape()
    |> Macro.to_string()
  end

  def build_union_types(union_types_text) do
    union_types_text |> String.split(" or ") |> Enum.map(&build_ftype/1)
  end

  defp build_api_paramaters_string(parameters) do
    Enum.map(parameters, fn p ->
      %{
        name: String.to_atom(p.name),
        type: build_api_ptype(p.type),
        required: p.required,
        description: p.description
      }
    end)
    |> Macro.escape()
    |> Macro.to_string()
  end

  defp build_api_ptype(type_string) do
    build_ftype(type_string)
  end
end
