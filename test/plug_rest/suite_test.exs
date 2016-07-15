defmodule SuiteTest do
  use ExUnit.Case
  use Plug.Test

  import PlugRest

  defmodule :rest_empty_resource do

    def init(conn, opts) do
      {:ok, conn, opts}
    end
  end

  defmodule :rest_expires_binary do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", %{}}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {"This is REST!", conn, state}
    end


    def expires(conn, state) do
      {"0", conn, state}
    end

  end

  defmodule :rest_expires do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", %{}}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {"This is REST!", conn, state}
    end


    def expires(conn, state) do
      {{{2012, 9, 21}, {22, 36, 14}}, conn, state}
    end


    def last_modified(conn, state) do
      {{{2012, 9, 21}, {22, 36, 14}}, conn, state}
    end

  end

  defmodule :rest_forbidden_resource do

    def init(conn, [var_forbidden]) do
      {:ok, conn, var_forbidden}
    end


    def allowed_methods(conn, state) do
      {["GET", "HEAD", "POST"], conn, state}
    end


    def forbidden(conn, state = true) do
      {true, conn, state}
    end

    def forbidden(conn, state = false) do
      {false, conn, state}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", %{}}, :to_text}], conn, state}
    end


    def content_types_accepted(conn, state) do
      {[{{"text", "plain", %{}}, :from_text}], conn, state}
    end


    def to_text(conn, state) do
      {"This is REST!", conn, state}
    end


    def from_text(conn, state) do
      {{true, conn.request_path}, conn, state}
    end

  end

  defmodule :rest_missing_callbacks do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def allowed_methods(conn, state) do
      {["GET", "PUT"], conn, state}
    end


    def content_types_accepted(conn, state) do
      {[{"application/json", :put_application_json}], conn, state}
    end


    def content_types_provided(conn, state) do
      {[{"text/plain", :get_text_plain}], conn, state}
    end

  end

  defmodule :rest_nodelete_resource do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def allowed_methods(conn, state) do
      {["GET", "HEAD", "DELETE"], conn, state}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", []}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {"This is REST!", conn, state}
    end

  end

  defmodule :rest_param_all do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def allowed_methods(conn, state) do
      {["GET", "PUT"], conn, state}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", :*}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {_, _, param} = :maps.get(:media_type, conn, {{"text", "plain"}, []})
      body = case(:if) do
        :if when param == :* ->
          "'*'"
        :if when param == [] ->
          "[]"
        :if when param != [] ->
          :erlang.iolist_to_binary(for({key, value} <- param, into: [], do: [key, ?=, value]))
      end
      {body, conn, state}
    end


    def content_types_accepted(conn, state) do
      {[{{"text", "plain", :*}, :put_text_plain}], conn, state}
    end


    def put_text_plain(conn, state) do
      {true, conn, state}
    end

  end

  defmodule :rest_patch_resource do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def allowed_methods(conn, state) do
      {["HEAD", "GET", "PATCH"], conn, state}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", %{}}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {"This is REST!", conn, state}
    end


    def content_types_accepted(conn, state) do
      case conn.method do
        "PATCH" ->
          {[{{"text", "plain", %{}}, :patch_text_plain}], conn, state}
        _ ->
          {[], conn, state}
      end
    end


    def patch_text_plain(conn, state) do
      case read_body(conn)  do
        {:ok, "stop", conn0} ->
          {:stop, Plug.Conn.put_status(conn0, 400), state}
        {:ok, "false", conn0} ->
          {false, conn0, state}
        {:ok, _body, conn0} ->
          {true, conn0, state}
      end
    end

  end

  defmodule :rest_post_charset_resource do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def allowed_methods(conn, state) do
      {["POST"], conn, state}
    end


    def content_types_accepted(conn, state) do
      {[{{"text", "plain", %{"charset" => "utf-8"}}, :from_text}], conn, state}
    end


    def from_text(conn, state) do
      {true, conn, state}
    end

  end

  defmodule :rest_postonly_resource do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def allowed_methods(conn, state) do
      {["POST"], conn, state}
    end


    def content_types_accepted(conn, state) do
      {[{{"text", "plain", :*}, :from_text}], conn, state}
    end


    def from_text(conn, state) do
      {true, conn, state}
    end

  end

  defmodule :rest_resource_etags do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def generate_etag(conn, state) do
      %{"type" => type} = fetch_query_params(conn).query_params
      case(type) do
        "tuple-weak" ->
          {{:weak, "etag-header-value"}, conn, state}
        "tuple-strong" ->
          {{:strong, "etag-header-value"}, conn, state}
        "binary-weak-quoted" ->
          {"W/\"etag-header-value\"", conn, state}
        "binary-strong-quoted" ->
          {"\"etag-header-value\"", conn, state}
        "binary-strong-unquoted" ->
          {"etag-header-value", conn, state}
        "binary-weak-unquoted" ->
          {"W/etag-header-value", conn, state}
      end
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", []}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {"This is REST!", conn, state}
    end

  end

  defmodule :rest_simple_resource do

    def init(conn, opts) do
      {:ok, conn, opts}
    end


    def content_types_provided(conn, state) do
      {[{{"text", "plain", %{}}, :get_text_plain}], conn, state}
    end


    def get_text_plain(conn, state) do
      {"This is REST!", conn, state}
    end

  end

  defmodule Router do
    use PlugRest

    resource "/param_all", :rest_param_all
    resource "/bad_accept", :rest_simple_resource
    resource "/bad_content_type", :rest_patch_resource
    resource "/simple", :rest_simple_resource
    resource "/forbidden_post", :rest_forbidden_resource, [true]
    resource "/simple_post", :rest_forbidden_resource, [false]
    resource "/missing_get_callbacks", :rest_missing_callbacks
    resource "/missing_put_callbacks", :rest_missing_callbacks
    resource "/nodelete", :rest_nodelete_resource
    resource "/post_charset", :rest_post_charset_resource
    resource "/postonly", :rest_postonly_resource
    resource "/patch", :rest_patch_resource
    resource "/resetags", :rest_resource_etags
    resource "/rest_expires", :rest_expires
    resource "/rest_expires_binary", :rest_expires_binary
    resource "/rest_empty_resource", :rest_empty_resource
  end

  test "rest status" do
    build_conn(:get, "/simple")
    |> test_status(200)
  end

  test "rest bad accept" do
    conn(:get, "/bad_accept")
    |> put_req_header("accept", "1")
    |> Router.call([])
    |> test_status(400)
  end

  test "rest bad content type" do
    conn(:patch, "/bad_content_type", "Whatever")
    |> put_req_header("content-type", "text/plain, text/html")
    |> Router.call([])
    |> test_status(415)
  end

  test "rest expires" do
    conn = build_conn(:get, "/rest_expires")

    test_status(conn, 200)

    expires = get_resp_header(conn, "expires")
    last_modified = get_resp_header(conn, "last-modified")

    assert expires == ["Fri, 21 Sep 2012 22:36:14 GMT"]
    assert expires == last_modified
  end

  test "rest expires binary" do
    build_conn(:get, "/rest_expires_binary")
    |> test_status(200)
    |> test_header("expires", "0")
  end

  test "rest forbidden post" do
    conn(:post, "/forbidden_post", "Hello world!")
    |> put_req_header("content-type", "text/plain")
    |> Router.call([])
    |> test_status(403)
  end

  test "rest simple post" do
    conn(:post, "/simple_post", "Hello world!")
    |> put_req_header("content-type", "text/plain")
    |> Router.call([])
    |> test_status(303)
  end

  test "rest missing get callbacks" do
    build_conn(:get, "/missing_get_callbacks")
    |> test_status(500)
  end

  test "rest missing put callbacks" do
    conn(:put, "/missing_put_callbacks")
    |> put_req_header("content-type", "application/json")
    |> Router.call([])
    |> test_status(500)
  end

  test "rest nodelete" do
    build_conn(:delete, "/nodelete")
    |> test_status(500)
  end

  test "rest options default" do
    build_conn(:options, "/rest_empty_resource")
    |> test_status(200)
    |> test_header("allow", "HEAD, GET, OPTIONS")
  end

  test "rest patch" do
    conn(:patch, "/patch", "whatever")
    |> put_req_header("content-type", "text/plain")
    |> Router.call([])
    |> test_status(204)

    conn(:patch, "/patch", "false")
    |> put_req_header("content-type", "text/plain")
    |> Router.call([])
    |> test_status(400)

    conn(:patch, "/patch", "stop")
    |> put_req_header("content-type", "text/plain")
    |> Router.call([])
    |> test_status(400)

    conn(:patch, "/patch", "bad_content_type")
    |> put_req_header("content-type", "application/json")
    |> Router.call([])
    |> test_status(415)
  end

  test "" do
    conn(:post, "/post_charset", "12345")
    |> put_req_header("content-type", "text/plain;charset=UTF-8")
    |> Router.call([])
    |> test_status(204)
  end

  test "rest post only" do
    conn(:post, "/postonly", "12345")
    |> put_req_header("content-type", "text/plain")
    |> Router.call([])
    |> test_status(204)
  end

  test "rest resource etags" do
    build_conn(:get, "/resetags?type=tuple-weak")
    |> test_status(200)
    |> test_header("etag", "W/\"etag-header-value\"")

    build_conn(:get, "/resetags?type=tuple-strong")
    |> test_status(200)
    |> test_header("etag", "\"etag-header-value\"")

    build_conn(:get, "/resetags?type=binary-weak-quoted")
    |> test_status(200)
    |> test_header("etag", "W/\"etag-header-value\"")

    build_conn(:get, "/resetags?type=binary-strong-quoted")
    |> test_status(200)
    |> test_header("etag", "\"etag-header-value\"")

    build_conn(:get, "/resetags?type=binary-strong-unquoted")
    |> test_status(500)

    build_conn(:get, "/resetags?type=binary-weak-unquoted")
    |> test_status(500)
  end

  defp build_conn(method, path) do
    conn(method, path) |> Router.call([])
  end

  defp test_status(conn, status) do
    assert conn.state == :sent
    assert conn.status == status
    conn
  end

  defp test_header(conn, key, value) do
    assert get_resp_header(conn, key) == [value]
    conn
  end
end
