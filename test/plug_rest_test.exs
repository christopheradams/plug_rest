defmodule PlugRestTest do
  use ExUnit.Case
  use Plug.Test

  doctest PlugRest

  defmodule IndexResource do
    @behaviour PlugRest.Resource

    def to_html(conn, state) do
      {"Plug REST", conn, state}
    end
  end

  defmodule ServiceUnavailableResource do
    @behaviour PlugRest.Resource

    def service_available(conn, state) do
      {false, conn, state}
    end
  end

  defmodule UnknownMethodsResource do
    @behaviour PlugRest.Resource

    def known_methods(conn, state) do
      {["GET", "POST"], conn, state}
    end
  end

  defmodule UriTooLongResource do
    @behaviour PlugRest.Resource

    def uri_too_long(conn, state) do
      {true, conn, state}
    end
  end

  defmodule UnallowedMethodsResource do
    @behaviour PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "POST"], conn, state}
    end
  end

  defmodule MalformedRequestResource do
    @behaviour PlugRest.Resource

    def malformed_request(conn, state) do
      {true, conn, state}
    end
  end

  defmodule UnauthorizedResource do
    @behaviour PlugRest.Resource

    def is_authorized(conn, state) do
      {{false, "AuthHeader"}, conn, state}
    end
  end

  defmodule ForbiddenResource do
    @behaviour PlugRest.Resource

    def forbidden(conn, state) do
      {true, conn, state}
    end
  end

  defmodule InvalidContentHeadersResource do
    @behaviour PlugRest.Resource

    def valid_content_headers(conn, state) do
      {false, conn, state}
    end
  end

  defmodule InvalidEntityLengthResource do
    @behaviour PlugRest.Resource

    def valid_entity_length(conn, state) do
      {false, conn, state}
    end
  end

  defmodule Router do
    use PlugRest

    resource "/", IndexResource
    resource "/service_unavailable", ServiceUnavailableResource
    resource "/unknown_methods", UnknownMethodsResource
    resource "/uri_too_long", UriTooLongResource
    resource "/unallowed_methods", UnallowedMethodsResource
    resource "/malformed_request", MalformedRequestResource
    resource "/unauthorized", UnauthorizedResource
    resource "/forbidden", ForbiddenResource
    resource "/invalid_content_headers", InvalidContentHeadersResource
    resource "/invalid_entity_length", InvalidEntityLengthResource
  end

  test "basic DSL is available" do
    conn = conn(:get, "/")

    conn = Router.call(conn, [])

    test_status(conn, 200)
    assert conn.resp_body == "Plug REST"
  end

  test "service unavailable returns 503" do
    build_conn(:get, "/service_unavailable") |> test_status(503)
  end

  test "unknown method returns 501" do
    build_conn(:delete, "/unknown_methods") |> test_status(501)
  end

  test "uri too long returns 414" do
    build_conn(:get, "/uri_too_long") |> test_status(414)
  end

  test "unallowed method returns 405" do
    build_conn(:delete, "/unallowed_methods") |> test_status(405)
  end

  test "malformed request returns 400" do
    build_conn(:get, "/malformed_request") |> test_status(400)
  end

  test "unauthorized request returns 401" do
    build_conn(:get, "/unauthorized") |> test_status(401)
  end

  test "forbidden request returns 403" do
    build_conn(:get, "/forbidden") |> test_status(403)
  end

  test "invalid content headers returns 501" do
    build_conn(:get, "/invalid_content_headers") |> test_status(501)
  end

  test "invalid entity length returns 413" do
    build_conn(:get, "/invalid_entity_length") |> test_status(413)
  end

  test "options" do
    conn = build_conn(:options, "/")
    test_status(conn, 200)
  end

  defp build_conn(method, path) do
    conn(method, path) |> Router.call([])
  end

  defp test_status(conn, status) do
    assert conn.state == :sent
    assert conn.status == status
  end
end
