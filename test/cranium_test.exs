defmodule CraniumTest do
  use ExUnit.Case
  doctest Cranium

  test "greets the world" do
    assert Cranium.hello() == :world
  end
end
