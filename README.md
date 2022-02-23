[![mix test](https://github.com/jechol/reather/workflows/mix%20test/badge.svg)](https://github.com/jechol/reather/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/reather.svg)](https://hex.pm/packages/reather)
[![License badge](https://img.shields.io/hexpm/l/reather.svg)](https://github.com/jechol/reather/blob/master/LICENSE.md)

`reather` is `def` for Witchcraft's Reader + Either monads.

## Installation

The package can be installed by adding `reather` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:reather, "~> 0.1"}]
end
```

To format `reather` like `def`, add following to your `.formatter.exs`

```elixir
locals_without_parens: [reather: 2]
```

## Usage

#### `reather`, `left/right`, `ask`, `inject`, `mock`

```elixir
defmodule Target do
  use Mok

  defmodule Impure do
    reather read("invalid") do
      return Left.new(:enoent)
    end

    reather read("valid") do
      return Right.new(99)
    end
  end

  reather read_and_multiply(filename) do
    input <- Impure.read(filename) |> Mok.inject()

    multiply(input)
  end

  reatherp multiply(input) do
    %{number: number} <- Mok.ask()

    return Right.new(input * number)
  end
end
```

```elixir
use Mok

mock = Mok.mock(%{&Target.Impure.read/1 => Right.new(77)})
# Same with
# mock = Mok.mock(%{&Target.Impure.read/1 => Mok.new(fn _env -> Right.new(77) end)})

assert %Left{left: :enoent} =
          Target.read_and_multiply("invalid") |> Mok.run(%{number: 10})

assert %Right{right: 770} =
          Target.read_and_multiply("invalid") |> Mok.run(%{number: 10} |> Map.merge(mock))

assert %Right{right: 990} = Target.read_and_multiply("valid") |> Mok.run(%{number: 10})
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details
