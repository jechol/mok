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
      :erlang.apply((&local_first/1) |> Mok.inject(mocks), [[1, 2, 3]])
    end

    def remote_call(mocks) do
      [1, 2, 3] |> List.first() |> Mok.inject(mocks)
    end

    def local_call(mocks) do
      [1, 2, 3] |> local_first() |> Mok.inject(mocks)
    end

    def remote_call_selector(mocks) do
      a = [1, 2, 3] |> List.first() |> Mok.inject(mocks, "unmatched")
      b = [1, 2, 3] |> List.first() |> Mok.inject(mocks, "here")
      c = [1, 2, 3] |> List.first() |> Mok.inject(mocks, nil)
      d = [1, 2, 3] |> List.first() |> Mok.inject(mocks)

      a + b + c + d
    end
  end

  test "remote_capture" do
    assert 1 == Target.remote_capture(%{})
    assert :remote == Target.remote_capture(Mok.mock(%{&List.first/1 => :remote}))
  end

  test "local_capture" do
    assert 1 == Target.local_capture(%{})
    assert :local == Target.local_capture(Mok.mock(%{&Target.local_first/1 => :local}))
  end

  test "remote_call" do
    assert 1 == Target.remote_call(%{})
    assert :remote == Target.remote_call(Mok.mock(%{&List.first/1 => :remote}))
  end

  test "local_call" do
    assert 1 == Target.local_call(%{})
    assert :local == Target.local_call(Mok.mock(%{&Target.local_first/1 => :local}))
  end

  test "remote_call_selector" do
    assert 4 == Target.remote_call_selector(%{})

    assert 211 ==
             Target.remote_call_selector(
               Mok.mock(%{
                 {&List.first/1, "here"} => 10,
                 &List.first/1 => 100
               })
             )
  end

  test "mock" do
    m =
      Mok.mock(%{
        &Enum.count/1 => 100,
        {&Enum.map/2, "here"} => 200
      })

    f1 = m[{&Enum.count/1, nil}]
    f2 = m[{&Enum.map/2, "here"}]

    assert :erlang.fun_info(f1)[:arity] == 1
    assert :erlang.fun_info(f2)[:arity] == 2

    assert f1.(nil) == 100
    assert f2.(nil, nil) == 200
  end
end
