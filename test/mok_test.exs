defmodule MokTest do
  use ExUnit.Case, async: false

  defmodule Target do
    require Mok

    defp local_first(list) do
      List.first(list)
    end

    def remote_capture(mocks) do
      :erlang.apply((&List.first/1) |> Mok.inject(mocks), [[1, 2, 3]])
    end

    def local_capture(mocks) do
      :erlang.apply((&local_first/1) |> Mok.inject(mocks), [[10, 20, 30]])
    end

    def remote_call(mocks) do
      [100, 200, 300] |> List.first() |> Mok.inject(mocks)
    end

    def local_call(mocks) do
      [1000, 2000, 3000] |> local_first() |> Mok.inject(mocks)
    end
  end

  test "remote_capture" do
    assert 1 == Target.remote_capture(%{})
    assert :remote == Target.remote_capture(Mok.mock(%{&List.first/1 => :remote}))
  end

  test "local_capture" do
    assert 10 == Target.local_capture(%{})
    assert :local == Target.local_capture(Mok.mock(%{&Target.local_first/1 => :local}))
  end

  test "remote_call" do
    assert 100 == Target.remote_call(%{})
    assert :remote == Target.remote_call(Mok.mock(%{&List.first/1 => :remote}))
  end

  test "local_call" do
    assert 1000 == Target.local_call(%{})
    assert :local == Target.local_call(Mok.mock(%{&Target.local_first/1 => :local}))
  end

  test "mock" do
    m =
      Mok.mock(%{
        &Enum.count/1 => 100,
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
