defmodule Telegex.TypeDefiner do
  @moduledoc false

  use TypedStruct

  # TODO: 添加生成联合类型模块的宏，会按照原始名称生成模块以及类型数组生成 `@type t :: Model1.t | Model2.t`。目的是让联合类型可以直接被当作普通类型使用。

  defmacro __using__(_) do
    quote do
      require Telegex.TypeDefiner
      import Telegex.TypeDefiner

      alias Telegex.TypeDefiner.{FieldMeta, ArrayType, UnionType}
    end
  end

  typedstruct module: ArrayType do
    field :elem_type, Telegex.TypeDefiner.field_type()
  end

  typedstruct module: UnionType do
    field :types, [Telegex.TypeDefiner.field_type()]
  end

  @type field_type ::
          :integer | :string | :boolean | :float | module | ArrayType.t() | UnionType.t()

  typedstruct module: FieldMeta do
    field :name, atom
    field :type, Telegex.TypeDefiner.field_type()
    field :optional, boolean
    field :description, String.t()
  end

  def def_moduledoc_ast(comment) do
    quote do
      @moduledoc unquote(comment)
    end
  end

  defp quoted(ast, caller) do
    {quoted, []} = Code.eval_quoted(ast, [], caller)

    quoted
  end

  def gen_field_ast(field) do
    type_spec = field_type_ast(field.type)

    name = field.name
    enforce = !field.optional

    quote do
      field unquote(name), unquote(type_spec), enforce: unquote(enforce)
    end
  end

  def field_type_ast(:string), do: quote(do: String.t())
  def field_type_ast(:boolean), do: quote(do: boolean)
  def field_type_ast(:integer), do: quote(do: integer)
  def field_type_ast(:float), do: quote(do: float)

  def field_type_ast(%ArrayType{elem_type: elem_type}) do
    quote do
      [unquote(field_type_ast(elem_type))]
    end
  end

  def field_type_ast(%UnionType{types: types}) do
    type_list_ast = Enum.map(types, &field_type_ast/1)

    union_type_ast = types_to_union(type_list_ast)

    quote do
      unquote(union_type_ast)
    end
  end

  def field_type_ast(module) do
    quote do
      unquote(module).t
    end
  end

  def types_to_union(ast_types) do
    _types_to_union(Enum.reverse(ast_types))
  end

  # 联合类型 AST 的例子，联合类型并不是一个平行的结构，而是一个深度嵌套结构。
  # 此处的联合类型指的是 `integer | String.t | boolean` 这种具有多种可能的 type 组合
  # {:|, [],
  #  [
  #    {:integer, [], Elixir},
  #    {:|, [],
  #     [
  #       {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]},
  #        [no_parens: true], []},
  #       {:boolean, [], Elixir}
  #     ]}
  #  ]}

  def _types_to_union(reversed_ast_types, i \\ 0, ast \\ nil) do
    current = Enum.at(reversed_ast_types, i)

    cond do
      i == 0 ->
        # 将倒数第二个和最后一个组合成第一个 ast
        ast = {:|, [], [Enum.at(reversed_ast_types, i + 1), current]}

        _types_to_union(reversed_ast_types, i + 2, ast)

      current != nil ->
        # 不断的将当前的 ast 和之前的 ast 组合成新的嵌套 ast
        _types_to_union(reversed_ast_types, i + 1, {:|, [], [current, ast]})

      true ->
        ast
    end
  end

  defmacro deftype(name, description, fields) do
    quoted_fields = quoted(fields, __CALLER__)

    fields_ast = Enum.map(quoted_fields, &gen_field_ast/1)

    references =
      if Enum.empty?(quoted_fields) do
        []
      else
        quoted_fields
        |> Enum.filter(&reference?(&1.type))
        |> Enum.map(fn f -> {f.name, f.type} end)
        |> Macro.escape()
      end

    quote do
      defmodule __MODULE__.unquote(name) do
        unquote(def_moduledoc_ast(description))

        # 存储所有引用其它类型的列表
        def __references__, do: unquote(references)
        def __mate__, do: :type

        typedstruct do
          unquote(fields_ast)
        end
      end

      # 自定义编码过程，去掉所有的 nil 字段
      defimpl Jason.Encoder, for: __MODULE__.unquote(name) do
        def encode(struct, opts) do
          struct
          |> Map.from_struct()
          |> Enum.filter(fn {_, v} -> v != nil end)
          |> Enum.into(%{})
          |> Jason.encode!()
        end
      end
    end
  end

  def reference?(type) when type in [:integer, :string, :boolean, :float] do
    false
  end

  def reference?(type) when is_struct(type, ArrayType) do
    reference?(type.elem_type)
  end

  def reference?(type) when is_struct(type, UnionType) do
    Enum.find(type.types, &reference?/1) == true
  end

  def reference?(type) when is_atom(type) do
    true
  end

  defmacro defunion(name, description, types) do
    types_ast = Enum.map(types, fn type -> field_type_ast(type) end)

    quote do
      defmodule __MODULE__.unquote(name) do
        unquote(def_moduledoc_ast(description))

        def __mate__, do: :union

        @type t :: unquote(types_to_union(types_ast))
      end
    end
  end
end
