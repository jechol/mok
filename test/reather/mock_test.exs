defmodule Reather.MockTest do
  use ExUnit.Case, async: false
  use Reather

  describe "mock" do
    test "non-reader" do
      m =
        Reather.mock(%{
          &Enum.count/1 => (fn -> 100 end).(),
          &Enum.map/2 => 200
        })

      f1 = m[&Enum.count/1]
      f2 = m[&Enum.map/2]

      assert :erlang.fun_info(f1)[:arity] == 1
      assert :erlang.fun_info(f2)[:arity] == 2

      assert f1.(nil) == 100
      assert f2.(nil, nil) == 200
    end
  end
end
