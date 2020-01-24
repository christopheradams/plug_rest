defmodule PlugRest.RouterTest do
  use ExUnit.Case
  use Plug.Test

  defmodule IndexResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      {"Plug REST", conn, state}
    end
  end

  defmodule UserCommentResource do
    use PlugRest.Resource

    def to_html(%{params: params} = conn, state) do
      user_id = params["user_id"]
      comment_id = params["comment_id"]

      {"#{user_id} : #{comment_id}", conn, state}
    end
  end

  defmodule GlobResource do
    use PlugRest.Resource

    def to_html(%{params: params} = conn, state) do
      bar = Enum.join(params["bar"], ", ")

      {"bar: #{bar}", conn, state}
    end
  end

  defmodule HostResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      {state, conn, state}
    end
  end

  defmodule PrivateAssignsResource do
    use PlugRest.Resource

    def to_html(conn, :assigns = state) do
      {conn.assigns.test, conn, state}
    end

    def to_html(conn, :private = state) do
      {conn.private.test, conn, state}
    end
  end

  defmodule OtherPlug do
    def init(options) do
      options
    end

    def call(conn, options) do
      send_resp(conn, 200, options)
    end
  end

  defmodule OtherRouter do
    use Plug.Router

    plug :match
    plug :dispatch

    match _ do
      send_resp(conn, 200, "Other")
    end
  end

  defmodule RestRouter do
    use PlugRest.Router

    plug :match
    plug :dispatch

    resource "/", IndexResource

    resource "/users/:user_id/comments/:comment_id", UserCommentResource

    resource "/glob/*_rest", IndexResource
    resource "/glob_params/*bar", GlobResource

    resource "/host", HostResource, "Host 1", host: "host1."
    resource "/host", HostResource, "Host 2", host: "host2."

    resource "/private", PrivateAssignsResource, :private, private: %{test: "private"}
    resource "/assigns", PrivateAssignsResource, :assigns, assigns: %{test: "assigns"}

    resource "/plug", OtherPlug, "Hello world"

    match "/match" do
      send_resp(conn, 200, "Matches!")
    end

    forward "/other", to: OtherRouter
  end

  test "resource works with any plug" do
    conn = conn(:get, "/plug")
    conn = RestRouter.call(conn, [])

    test_status(conn, 200)
    assert conn.resp_body == "Hello world"
  end

  test "basic DSL is available" do
    conn = conn(:get, "/")

    conn = RestRouter.call(conn, [])

    test_status(conn, 200)
    assert conn.resp_body == "Plug REST"
  end

  test "match can match known route" do
    conn =
      build_conn(:get, "/match")
      |> test_status(200)

    assert conn.resp_body == "Matches!"
  end

  test "match any can catch unknown route" do
    conn =
      build_conn(:get, "/unknown")
      |> test_status(404)

    assert conn.resp_body == ""
  end

  test "dynamic path populates connection params" do
    conn =
      conn(:get, "/users/1234/comments/987")
      |> RestRouter.call([])

    test_status(conn, 200)
    assert conn.resp_body == "1234 : 987"
  end

  test "glob resource dispatch" do
    conn =
      build_conn(:get, "/glob/value")
      |> test_status(200)

    assert conn.resp_body == "Plug REST"
  end

  test "glob values resource dispatch" do
    conn =
      build_conn(:get, "/glob_params/value")
      |> test_status(200)

    assert conn.resp_body == "bar: value"

    conn =
      build_conn(:get, "/glob_params/item/extra")
      |> test_status(200)

    assert conn.resp_body == "bar: item, extra"
  end

  test "host option" do
    conn1 =
      conn(:get, "/host")
      |> Map.put(:host, "host1.example.com")
      |> RestRouter.call([])

    assert conn1.resp_body == "Host 1"

    conn2 =
      conn(:get, "/host")
      |> Map.put(:host, "host2.example.com")
      |> RestRouter.call([])

    assert conn2.resp_body == "Host 2"
  end

  test "private option" do
    conn =
      conn(:get, "/private")
      |> RestRouter.call([])

    assert conn.resp_body == "private"
  end

  test "assigns option" do
    conn =
      conn(:get, "/assigns")
      |> RestRouter.call([])

    assert conn.resp_body == "assigns"
  end

  test "forward" do
    conn =
      build_conn(:get, "/other")
      |> test_status(200)

    assert conn.resp_body == "Other"
  end

  ## Plugs test

  defmodule RequestIdResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      request_id = Plug.Conn.get_resp_header(conn, "x-request-id")
      {request_id, conn, state}
    end
  end

  defmodule PlugsRouter do
    use PlugRest.Router

    plug Plug.RequestId

    plug :match
    plug :dispatch

    resource "/request_id", RequestIdResource
  end

  test "plugs in router" do
    request_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    conn =
      conn(:get, "/request_id")
      |> put_req_header("x-request-id", request_id)
      |> PlugsRouter.call([])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == request_id
  end

  ## Utility functions

  defp build_conn(method, path) do
    build_conn(method, path, RestRouter)
  end

  defp build_conn(method, path, router) do
    conn = conn(method, path)
    apply(router, :call, [conn, []])
  end

  defp test_status(conn, status) do
    assert conn.state == :sent
    assert conn.status == status
    conn
  end
end
