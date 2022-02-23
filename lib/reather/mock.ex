defmodule Reather.Mock do
  @moduledoc false

  def decorate_with_fn({{:&, _, [{:/, _, [{{:., _, [m, f]}, _, []}, a]}]} = capture, v}) do
    const_fn = {:fn, [], [{:->, [], [Macro.generate_arguments(a, __MODULE__), v]}]}

    value =
      quote do
        {:module, unquote(m)} = Code.ensure_loaded(unquote(m))
        unquote(const_fn)
      end

    {capture, value}
  end

  def decorate_with_fn({k, v}) do
    {k, v}
  end
end
