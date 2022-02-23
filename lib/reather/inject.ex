defmodule Reather.Macros do
  defmacro __using__([]) do
  end

  # Capture
  defmacro inject(
             {:&, _, [{:/, _, [{{:., _, [mod, name]}, [{:no_parens, true}, _], []}, arity]}]},
             mock_map
           ) do
    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(unquote(mock_map), fun, fun)
    end
  end

  defmacro inject({:&, _, [{:/, _, [{name, _, _}, arity]}]} = ast, mock_map) do
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(unquote(mock_map), fun, unquote(ast))
    end
  end

  # Call
  defmacro inject({{:., _, [mod, name]}, _, args}, mock_map)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Map.get(unquote(mock_map), fun, fun) |> :erlang.apply(unquote(args))
    end
  end

  defmacro inject({name, _, args} = local_call, mock_map)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))

      case Map.fetch(unquote(mock_map), fun) do
        {:ok, mock} -> :erlang.apply(mock, unquote(args))
        :error -> unquote(local_call)
      end
    end
  end

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

  # defmacro mock({:%{}, context, mocks}) do
  #   alias Reather.Mock

  #   {:%{}, context, mocks |> Enum.map(&Mock.decorate_with_fn/1)}
  #   |> trace()
  # end

  # Private

  defp find_func_module(name_arity, mod_funs, caller_mod) do
    remote =
      mod_funs
      |> Enum.find(fn {_mod, funs} ->
        name_arity in funs
      end)

    if remote != nil do
      {remote_mod, _} = remote
      remote_mod
    else
      caller_mod
    end
  end

  defp get_fa({:when, _, [name_args, _when_cond]}) do
    get_fa(name_args)
  end

  defp get_fa({name, _, args}) when is_list(args) do
    {name, args |> Enum.count()}
  end

  defp get_fa({name, _, _}) do
    {name, 0}
  end
end
