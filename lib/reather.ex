defmodule Reather do
  defmacro __using__([]) do
    quote do
      use Reather.Macros
    end
  end

  use Reather.Macros

  defmacro inject(call, env) do
    quote do
      Reather.Macros.inject(unquote(call), unquote(env))
    end
  end

  defmacro mock(mocks) do
    quote do
      Reather.Macros.mock(unquote(mocks))
    end
  end
end
