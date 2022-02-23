defmodule Reather.CaptureTest do
  use ExUnit.Case, async: false
  use Reather

  defmodule Target do
    use Reather

    defp local_first(list) do
      List.first(list)
    end

    def external_capture(mock) do
      :erlang.apply((&List.first/1) |> Reather.inject(mock), [[1, 2]])
    end

    def local_capture(mock) do
      :erlang.apply((&local_first/1) |> Reather.inject(mock), [[100, 200]])
    end
  end

  test "external" do
    assert 1 == Target.external_capture(%{})

    assert :external == Target.external_capture(Reather.mock(%{&List.first/1 => :external}))
  end

  test "local" do
    assert 100 == Target.local_capture(%{})

    assert :local == Target.local_capture(Reather.mock(%{&Target.local_first/1 => :local}))
  end
end
