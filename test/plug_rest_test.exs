defmodule PlugRestTest do
  use ExUnit.Case
  use Plug.Test

  doctest PlugRest

  defmodule IndexResource do
    @behaviour PlugRest.Resource
  end

  defmodule Router do
    use PlugRest

    resource "/", IndexResource
  end

  test "basic DSL is available" do
    conn = conn(:get, "/")

    conn = Router.call(conn, [])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Plug REST"
  end
end
