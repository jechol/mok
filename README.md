[![mix test](https://github.com/jechol/mok/workflows/mix%20test/badge.svg)](https://github.com/jechol/mok/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/mok.svg)](https://hex.pm/packages/mok)
[![License badge](https://img.shields.io/hexpm/l/mok.svg)](https://github.com/jechol/mok/blob/main/LICENSE.md)

`mok` is small library to inject and mock functions easily.

## Installation

The package can be installed by adding `mok` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:mok, "~> 0.1"}]
end
```

## Usage

#### `inject`, `mock`

```elixir

  defmodule Target do
    require Mok

    def call(mocks) do
      a = [1, 2, 3] |> List.first() |> Mok.inject(mocks, "unmatched") # 1 (not injected)
      b = [1, 2, 3] |> List.first() |> Mok.inject(mocks, "matched") # 10 (injected)
      c = [1, 2, 3] |> List.first() |> Mok.inject(mocks, nil) # 1 (not injected)
      d = [1, 2, 3] |> List.first() |> Mok.inject(mocks) # 100 (injected)

      a + b + c + d
    end
  end
```

```elixir
require Mok

assert 4 == Target.call(%{})

assert 112 ==
          Target.call(
            Mok.mock(%{
              {&List.first/1, "matched"} => 10,
              &List.first/1 => 100
            })
          )
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
