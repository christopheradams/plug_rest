defmodule PlugRest.SuiteTest do
  use ExUnit.Case
  use Plug.Test

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
      {[{{"text", "plain", %{}}, :get_text_plain}], conn, state}
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
      media_type = PlugRest.Conn.get_media_type(conn)
      body = case media_type do
               "" ->
                 "'*'"
               {_, _, %{"level" => level}} ->
                 "level=#{level}"
               {_, _, %{}} ->
                 "%{}"
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
      {[{{"text", "plain", %{}}, :from_text}], conn, state}
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
      {[{{"text", "plain", %{}}, :get_text_plain}], conn, state}
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

  defmodule RestRouter do
    use PlugRest.Router

    resource "/param_all", :rest_param_all
    resource "/bad_accept", :rest_simple_resource
    resource "/bad_content_type", :rest_patch_resource
    resource "/simple", :rest_simple_resource
    resource "/forbidden_post", :rest_forbidden_resource, state: [true]
    resource "/simple_post", :rest_forbidden_resource, state: [false]
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

  test "rest accept without param" do
    conn(:get, "/param_all")
    |> put_req_header("accept", "text/plain")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_body("%{}")
  end

  test "rest accept with param" do
    conn(:get, "/param_all")
    |> put_req_header("accept", "text/plain;level=1")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_body("level=1")
  end

  test "rest accept with param and quality" do
    conn(:get, "/param_all")
    |> put_req_header("accept", "text/plain;level=1;q=0.8, text/plain;level=2;q=0.5")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_body("level=1")
  end

  test "rest accept with param and quality, with different priority" do
    conn(:get, "/param_all")
    |> put_req_header("accept", "text/plain;level=1;q=0.5, text/plain;level=2;q=0.8")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_body("level=2")
  end

  test "rest without accept" do
    conn(:get, "/param_all")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_body("'*'")
  end

  test "rest content-type without param" do
    conn(:put, "/param_all", "Hello world!")
    |> put_req_header("content-type", "text/plain")
    |> RestRouter.call([])
    |> test_status(204)
  end

  test "rest content-type with param" do
    conn(:put, "/param_all", "Hello world!")
    |> put_req_header("content-type", "text/plain; charset=utf-8")
    |> RestRouter.call([])
    |> test_status(204)
  end

  test "rest status" do
    build_conn(:get, "/simple")
    |> test_status(200)
  end

  test "rest bad accept" do
    conn(:get, "/bad_accept")
    |> put_req_header("accept", "1")
    |> RestRouter.call([])
    |> test_status(400)
  end

  test "rest bad content type" do
    conn(:patch, "/bad_content_type", "Whatever")
    |> put_req_header("content-type", "text/plain, text/html")
    |> RestRouter.call([])
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
    |> RestRouter.call([])
    |> test_status(403)
  end

  test "rest simple post" do
    conn(:post, "/simple_post", "Hello world!")
    |> put_req_header("content-type", "text/plain")
    |> RestRouter.call([])
    |> test_status(303)
  end

  test "rest missing get callbacks" do
    build_conn(:get, "/missing_get_callbacks")
    |> test_status(500)
  end

  test "rest missing put callbacks" do
    conn(:put, "/missing_put_callbacks")
    |> put_req_header("content-type", "application/json")
    |> RestRouter.call([])
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
    |> RestRouter.call([])
    |> test_status(204)

    conn(:patch, "/patch", "false")
    |> put_req_header("content-type", "text/plain")
    |> RestRouter.call([])
    |> test_status(400)

    conn(:patch, "/patch", "stop")
    |> put_req_header("content-type", "text/plain")
    |> RestRouter.call([])
    |> test_status(400)

    conn(:patch, "/patch", "bad_content_type")
    |> put_req_header("content-type", "application/json")
    |> RestRouter.call([])
    |> test_status(415)
  end

  test "" do
    conn(:post, "/post_charset", "12345")
    |> put_req_header("content-type", "text/plain;charset=UTF-8")
    |> RestRouter.call([])
    |> test_status(204)
  end

  test "rest post only" do
    conn(:post, "/postonly", "12345")
    |> put_req_header("content-type", "text/plain")
    |> RestRouter.call([])
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

  test "rest resource if none match" do
    conn(:get, "/resetags?type=tuple-weak")
    |> put_req_header("if-none-match", "W/\"etag-header-value\"")
    |> RestRouter.call([])
    |> test_status(304)
    |> test_header("etag", "W/\"etag-header-value\"")

    conn(:get, "/resetags?type=tuple-strong")
    |> put_req_header("if-none-match", "\"etag-header-value\"")
    |> RestRouter.call([])
    |> test_status(304)
    |> test_header("etag", "\"etag-header-value\"")

    conn(:get, "/resetags?type=binary-weak-quoted")
    |> put_req_header("if-none-match", "\"etag-header-value\"")
    |> RestRouter.call([])
    |> test_status(304)
    |> test_header("etag", "W/\"etag-header-value\"")

    conn(:get, "/resetags?type=binary-strong-quoted")
    |> put_req_header("if-none-match", "\"etag-header-value\"")
    |> RestRouter.call([])
    |> test_status(304)
    |> test_header("etag", "\"etag-header-value\"")
  end

  defp build_conn(method, path) do
    conn(method, path) |> RestRouter.call([])
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

  defp test_body(conn, body) do
    assert body == conn.resp_body
    conn
  end
end
