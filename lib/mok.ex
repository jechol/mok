defmodule Mok do
  defmodule Nil do
    defstruct []
  end

  defmacro inject(capture_or_call, mocks, selector \\ Macro.escape(%Nil{}))

  # Remote capture
  defmacro inject(
             {:&, _, [{:/, _, [{{:., _, [mod, name]}, [{:no_parens, true}, _], []}, arity]}]},
             mocks,
             selector
           ) do
    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Mok.find_func(unquote(mocks), fun, unquote(selector), fun)
    end
  end

  # Local capture
  defmacro inject({:&, _, [{:/, _, [{name, _, _}, arity]}]} = ast, mocks, selector) do
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Mok.find_func(unquote(mocks), fun, unquote(selector), unquote(ast))
    end
  end

  # Remote call
  defmacro inject({{:., _, [mod, name]}, _, args}, mocks, selector)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))
      Mok.find_func(unquote(mocks), fun, unquote(selector), fun) |> :erlang.apply(unquote(args))
    end
  end

  # Local call
  defmacro inject({name, _, args} = local_call, mocks, selector)
           when is_atom(name) and is_list(args) do
    arity = Enum.count(args)
    %Macro.Env{module: caller_mod, functions: mod_funs} = __CALLER__
    mod = find_func_module({name, arity}, mod_funs, caller_mod)

    quote do
      fun = :erlang.make_fun(unquote(mod), unquote(name), unquote(arity))

      case Mok.find_func(unquote(mocks), fun, unquote(selector), nil) do
        nil -> unquote(local_call)
        mock -> :erlang.apply(mock, unquote(args))
      end
    end
  end

  def find_func(mocks, fun, %Nil{}, default) do
    Map.get(mocks, fun, default)
  end

  def find_func(mocks, fun, selector, default) do
    Map.get(mocks, {fun, selector}, default)
  end

  # Mock
  def mock(%{} = map) do
    map
    |> Map.new(fn
      {f, v} when is_function(f) ->
        {f, const_fn(Function.info(f)[:arity], v)}

      {{f, selector}, v} when is_function(f) ->
        {{f, selector}, const_fn(Function.info(f)[:arity], v)}
    end)
  end

  # Private

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

  defp find_func_module(name_arity, mod_funs, caller_mod) do
    mod_funs
    |> Enum.find(fn {_mod, funs} ->
      name_arity in funs
    end)
    |> case do
      {remote_mod, _funs} -> remote_mod
      nil -> caller_mod
    end
  end
end
