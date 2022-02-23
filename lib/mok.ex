defmodule Reather do
  # Remote capture
  defmacro inject(
             {:&, _, [{:/, _, [{{:., _, [mod, name]}, [{:no_parens, true}, _], []}, arity]}]},
             mocks
           ) do
    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(unquote(mocks), fun, fun)
    end
  end

  # Local capture
  defmacro inject({:&, _, [{:/, _, [{name, _, _}, arity]}]} = ast, mocks) do
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(unquote(mocks), fun, unquote(ast))
    end
  end

  # Remote call
  defmacro inject({{:., _, [mod, name]}, _, args}, mocks)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(unquote(mocks), fun, fun) |> :erlang.apply(unquote(args))
    end
  end

  # Local call
  defmacro inject({name, _, args} = local_call, mocks)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))

      case Map.fetch(unquote(mocks), fun) do
        {:ok, mock} -> :erlang.apply(mock, unquote(args))
        :error -> unquote(local_call)
      end
    end
  end

  # Mock
  def mock(%{} = map) do
    map
    |> Map.new(fn
      {f, v} when is_function(f) -> {f, const_fn(Function.info(f)[:arity], v)}
      {{f, label}, v} when is_function(f) -> {{f, label}, const_fn(Function.info(f)[:arity], v)}
    end)
  end

  defp const_fn(0, v), do: fn -> v end
  defp const_fn(1, v), do: fn _a -> v end
  defp const_fn(2, v), do: fn _a, _b -> v end
  defp const_fn(3, v), do: fn _a, _b, _c -> v end
  defp const_fn(4, v), do: fn _a, _b, _c, _d -> v end
  defp const_fn(5, v), do: fn _a, _b, _c, _d, _e -> v end
  defp const_fn(6, v), do: fn _a, _b, _c, _d, _e, _f -> v end
  defp const_fn(7, v), do: fn _a, _b, _c, _d, _e, _f, _g -> v end
  defp const_fn(8, v), do: fn _a, _b, _c, _d, _e, _f, _g, _h -> v end
  defp const_fn(9, v), do: fn _a, _b, _c, _d, _e, _f, _g, _h, _i -> v end

  # Private

  defp find_func_module(name_arity, mod_funs, caller_mod) do
    remote =
      mod_funs
      |> Enum.find(fn {_mod, funs} ->
        name_arity in funs
      end)

    case remote do
      {remote_mod, _funs} -> remote_mod
      nil -> caller_mod
    end
  end
end
