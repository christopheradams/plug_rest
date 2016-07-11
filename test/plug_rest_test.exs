defmodule PlugRestTest do
  use ExUnit.Case
  use Plug.Test

  doctest PlugRest

  defmodule IndexResource do
    @behaviour PlugRest.Resource
  end

  defmodule ServiceUnavailableResource do
    @behaviour PlugRest.Resource

    def service_available(conn, state) do
      {false, conn, state}
    end
  end

  defmodule Router do
    use PlugRest

    resource "/", IndexResource
    resource "/service_unavailable", ServiceUnavailableResource
  end

  test "basic DSL is available" do
    conn = conn(:get, "/")

    conn = Router.call(conn, [])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Plug REST"
  end

  test "service unavailable returns 503" do
    conn = conn(:get, "/service_unavailable")

    conn = Router.call(conn, [])

    assert conn.state == :sent
    assert conn.status == 503
  end
end
