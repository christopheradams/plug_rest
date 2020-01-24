defmodule PlugRest.ResourceTest do
  use ExUnit.Case
  use Plug.Test

  ## Resources

  defmodule IndexResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      {"Plug REST", conn, state}
    end
  end

  defmodule InitResource do
    use PlugRest.Resource

    def init(conn, state) do
      {state, conn, state}
    end

    def to_html(conn, state) do
      {"#{state}", conn, state}
    end
  end

  defmodule ErrorResource do
    use PlugRest.Resource

    def service_available(_conn, _state) do
      raise "oops"
    end
  end

  defmodule ServiceUnavailableResource do
    use PlugRest.Resource

    def service_available(conn, state) do
      {false, conn, state}
    end
  end

  defmodule KnownMethodsResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "POST", "MOVE"], conn, state}
    end

    def known_methods(conn, state) do
      {["GET", "POST", "TRACE", "MOVE"], conn, state}
    end

    def to_html(conn, state) do
      {conn.method, conn, state}
    end
  end

  defmodule UriTooLongResource do
    use PlugRest.Resource

    def uri_too_long(conn, state) do
      {true, conn, state}
    end
  end

  defmodule AllowedMethodsResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["HEAD", "GET", "POST", "OPTIONS"], conn, state}
    end
  end

  defmodule MalformedRequestResource do
    use PlugRest.Resource

    def malformed_request(conn, state) do
      {true, conn, state}
    end
  end

  defmodule UnauthorizedResource do
    use PlugRest.Resource

    def is_authorized(conn, state) do
      {{false, "AuthHeader"}, conn, state}
    end
  end

  defmodule ForbiddenResource do
    use PlugRest.Resource

    def forbidden(conn, state) do
      {true, conn, state}
    end
  end

  defmodule InvalidContentHeadersResource do
    use PlugRest.Resource

    def valid_content_headers(conn, state) do
      {false, conn, state}
    end
  end

  defmodule InvalidEntityLengthResource do
    use PlugRest.Resource

    def valid_entity_length(conn, state) do
      {false, conn, state}
    end
  end

  defmodule ConflictResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["PUT"], conn, state}
    end

    def is_conflict(conn, state) do
      {true, conn, state}
    end
  end

  defmodule DeleteResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["DELETE"], conn, state}
    end

    def delete_resource(conn, state) do
      {true, conn, state}
    end

    def delete_completed(conn, state) do
      %{"completed" => completed} = fetch_query_params(conn).query_params

      case completed do
        "true" ->
          {true, conn, state}

        _ ->
          {false, conn, state}
      end
    end
  end

  defmodule ProcessCreateResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "OPTIONS", "HEAD", "PUT", "POST", "DELETE"], conn, state}
    end

    def resource_exists(conn, %{exists: false} = state) do
      {false, conn, state}
    end

    def resource_exists(conn, state) do
      {true, conn, state}
    end

    def allow_missing_post(conn, state) do
      {true, conn, state}
    end

    def to_html(conn, state) do
      {"To HTML", conn, state}
    end

    def content_types_accepted(conn, state) do
      {[{"mixed/multipart", :from_multipart}], conn, state}
    end

    def from_multipart(conn, %{location: :new} = state) do
      conn = put_body(conn, state, "#{conn.method} from multipart")
      {{true, "/new/1234"}, conn, state}
    end

    def from_multipart(conn, %{location: :manual} = state) do
      conn =
        conn
        |> put_resp_header("location", "/new/1234")
        |> put_body(state, "#{conn.method} from multipart")

      {true, conn, state}
    end

    def from_multipart(conn, state) do
      conn = put_body(conn, state, "#{conn.method} from multipart")
      {true, conn, state}
    end

    def delete_resource(conn, state) do
      {true, conn, state}
    end

    def delete_completed(conn, state) do
      conn = put_body(conn, state, "#{conn.method} resource")
      {true, conn, state}
    end

    defp put_body(conn, %{body: true} = _state, body) do
      put_rest_body(conn, body)
    end

    defp put_body(conn, _state, _body) do
      conn
    end
  end

  defmodule JsonResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "POST"], conn, state}
    end

    def content_types_provided(conn, state) do
      {[{{"application", "json", :*}, :to_json}], conn, state}
    end

    def content_types_accepted(conn, state) do
      {[{{"application", "json", :*}, :from_json}], conn, state}
    end

    def to_json(conn, state) do
      {"{}", conn, state}
    end

    def from_json(conn, state) do
      {{true, "/new"}, conn, state}
    end
  end

  defmodule BinaryCtpResource do
    use PlugRest.Resource

    def content_types_provided(conn, state) do
      {[{"application/json", :to_json}], conn, state}
    end

    def to_json(conn, state) do
      {"{}", conn, state}
    end
  end

  defmodule HypermediaResource do
    use PlugRest.Resource

    def content_types_provided(conn, state) do
      {[{{"text", "html", %{}}, :to_html}, {{"application", "json", %{}}, :to_json}], conn, state}
    end

    def languages_provided(conn, state) do
      {["de", "en"], conn, state}
    end

    def to_html(conn, state) do
      {"Media", conn, state}
    end

    def to_json(conn, state) do
      {"{\"title\": \"Media\"}", conn, state}
    end
  end

  defmodule AcceptAnyResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "POST"], conn, state}
    end

    def content_types_accepted(conn, state) do
      {[{:*, :from_content}], conn, state}
    end

    def from_content(conn, state) do
      {true, conn, state}
    end

    def to_html(conn, state) do
      {"html", conn, state}
    end
  end

  defmodule CtpParamsResource do
    use PlugRest.Resource

    def content_types_provided(conn, %{params: params} = state) do
      {[{{"text", "html", params}, :to_html}], conn, state}
    end

    def to_html(conn, state) do
      {"HTML", conn, state}
    end
  end

  defmodule LanguagesResource do
    use PlugRest.Resource

    def languages_provided(conn, state) do
      {["de", "en"], conn, state}
    end

    def to_html(conn, state) do
      {"Languages", conn, state}
    end
  end

  defmodule CharsetResource do
    use PlugRest.Resource

    def charsets_provided(conn, state) do
      {["utf-8", "unicode-1-1"], conn, state}
    end

    def to_html(conn, state) do
      {"Charsets", conn, state}
    end
  end

  defmodule ResourceExists do
    use PlugRest.Resource

    def resource_exists(conn, false = state) do
      {false, conn, state}
    end

    def resource_exists(conn, state) do
      {true, conn, state}
    end
  end

  defmodule PreviouslyExisted do
    use PlugRest.Resource

    def resource_exists(conn, state) do
      {false, conn, state}
    end

    def previously_existed(conn, false = state) do
      {false, conn, state}
    end
  end

  defmodule MovedPermanentlyResource do
    use PlugRest.Resource

    def resource_exists(conn, state) do
      {false, conn, state}
    end

    def previously_existed(conn, state) do
      {true, conn, state}
    end

    def moved_permanently(conn, state) do
      {{true, "/moved"}, conn, state}
    end
  end

  defmodule MovedTemporarilyResource do
    use PlugRest.Resource

    def resource_exists(conn, state) do
      {false, conn, state}
    end

    def previously_existed(conn, state) do
      {true, conn, state}
    end

    def moved_temporarily(conn, state) do
      {{true, "/temp"}, conn, state}
    end
  end

  defmodule MissingPostResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "HEAD", "OPTIONS", "POST"], conn, state}
    end

    def resource_exists(conn, state) do
      {false, conn, state}
    end

    def allow_missing_post(_conn, :no_call) do
      :no_call
    end

    def allow_missing_post(conn, a_m_p = state) do
      {a_m_p, conn, state}
    end

    def content_types_accepted(conn, state) do
      {[{"mixed/multipart", :from_content}], conn, state}
    end

    def from_content(conn, state) do
      {true, conn, state}
    end

    def to_html(conn, state) do
      {"allow missing", conn, state}
    end
  end

  defmodule GoneResource do
    use PlugRest.Resource

    def resource_exists(conn, state) do
      {false, conn, state}
    end

    def previously_existed(conn, state) do
      {true, conn, state}
    end

    def moved_temporarily(conn, state) do
      {false, conn, state}
    end
  end

  defmodule LastModifiedResource do
    use PlugRest.Resource

    def last_modified(conn, state) do
      modified = {{2016, 7, 17}, {11, 49, 29}}
      {modified, conn, state}
    end

    def to_html(conn, state) do
      {"Modified", conn, state}
    end
  end

  defmodule NilModifiedResource do
    use PlugRest.Resource

    def last_modified(conn, state) do
      {nil, conn, state}
    end

    def to_html(conn, state) do
      {"Modified", conn, state}
    end
  end

  defmodule PipelineResource do
    use PlugRest.Resource
    use Plug.Builder

    plug :hello
    plug :rest

    def to_html(conn, state) do
      {conn.private.message, conn, state}
    end

    def hello(conn, _opts) do
      put_private(conn, :message, "Hello")
    end
  end

  defmodule ChunkedResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      body = ["HELLO", "WORLD"]
      {{:chunked, body}, conn, state}
    end
  end

  defmodule SendFileResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      {:ok, cwd} = File.cwd()
      file = "test/fixtures/hello_world.txt"
      path = Path.absname(file, cwd)
      {{:file, path}, conn, state}
    end
  end

  defmodule StopResource do
    use PlugRest.Resource

    def service_available(conn, :send = state) do
      conn2 = conn |> send_resp(200, "Sent")
      {:stop, conn2, state}
    end

    def service_available(conn, :resp = state) do
      conn2 = conn |> resp(200, "Resp")
      {:stop, conn2, state}
    end

    def service_available(conn, state) do
      {:stop, conn, state}
    end
  end

  ## Resource callbacks

  ### init

  test "init ok" do
    conn(:get, "/") |> call_resource(InitResource, :ok) |> test_status(200)
  end

  test "init error" do
    conn(:get, "/") |> call_resource(InitResource, :error) |> test_status(500)
  end

  ### service_available

  test "service unavailable returns 503" do
    conn(:get, "/") |> call_resource(ServiceUnavailableResource) |> test_status(503)
  end

  ### known_methods

  test "unknown method returns 501" do
    conn(:delete, "/") |> call_resource(KnownMethodsResource) |> test_status(501)
  end

  test "custom known and unallowed method" do
    conn(:trace, "/") |> call_resource(KnownMethodsResource) |> test_status(405)
  end

  test "custom known and allowed method" do
    conn(:move, "/") |> call_resource(KnownMethodsResource) |> test_status(200)
  end

  ### uri_too_long

  test "uri too long returns 414" do
    conn(:get, "/") |> call_resource(UriTooLongResource) |> test_status(414)
  end

  ### allowed_methods

  test "unallowed method returns 405" do
    conn = conn(:delete, "/") |> call_resource(AllowedMethodsResource) |> test_status(405)
    test_header(conn, "allow", "HEAD, GET, POST, OPTIONS")
  end

  ### malformed_request

  test "malformed request returns 400" do
    conn(:get, "/") |> call_resource(MalformedRequestResource) |> test_status(400)
  end

  ### is_authorized

  test "unauthorized request returns 401" do
    conn(:get, "/") |> call_resource(UnauthorizedResource) |> test_status(401)
  end

  ### forbidden

  test "forbidden request returns 403" do
    conn(:get, "/") |> call_resource(ForbiddenResource) |> test_status(403)
  end

  ### valid_content_headers

  test "invalid content headers returns 501" do
    conn(:get, "/") |> call_resource(InvalidContentHeadersResource) |> test_status(501)
  end

  ### valid_entity_length

  test "invalid entity length returns 413" do
    conn(:get, "/") |> call_resource(InvalidEntityLengthResource) |> test_status(413)
  end

  ### is_conflict

  test "put when conflict" do
    conn(:put, "/") |> call_resource(ConflictResource) |> test_status(409)
  end

  ### delete_resource

  test "delete resource" do
    conn(:delete, "/delete?completed=true") |> call_resource(DeleteResource) |> test_status(204)
  end

  ### delete_completed

  test "delete not completed" do
    conn(:delete, "/delete?completed=false") |> call_resource(DeleteResource) |> test_status(202)
  end

  ### content negotiation

  # TODO: Return 201
  test "post new resource" do
    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{exists: false})
    |> test_status(204)
  end

  test "post new resource with new location" do
    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{location: :new, exists: false})
    |> test_status(201)
  end

  test "post new resource with manual location" do
    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{location: :manual, exists: false})
    |> test_status(201)
  end

  test "put new resource" do
    conn(:put, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{exists: false})
    |> test_status(201)
  end

  # TODO: Don't crash
  test "put new resource with new location" do
    assert_raise CaseClauseError, fn ->
      conn(:put, "/", "test=test")
      |> put_req_header("content-type", "mixed/multipart")
      |> call_resource(ProcessCreateResource, %{location: :new, exists: false})
      |> test_status(201)
    end
  end

  test "put new resource with manual location" do
    conn(:put, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{location: :manual, exists: false})
    |> test_status(201)
  end

  # TODO: Don't crash
  test "put existing resource with new location" do
    assert_raise CaseClauseError, fn ->
      conn(:put, "/", "test=test")
      |> put_req_header("content-type", "mixed/multipart")
      |> call_resource(ProcessCreateResource, %{location: :new, exists: true})
      |> test_status(303)
    end
  end

  # TODO: Return 303
  test "put existing resource with manual location" do
    conn(:put, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{location: :manual, exists: true})
    |> test_status(204)
  end

  test "post existing resource with new location" do
    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{location: :new, exists: true})
    |> test_status(303)
  end

  # TODO: Return 303
  test "post existing resource with manual location" do
    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(ProcessCreateResource, %{location: :manual, exists: true})
    |> test_status(204)
  end

  test "response body with put" do
    conn =
      conn(:put, "/", "test=test")
      |> put_req_header("content-type", "mixed/multipart")
      |> call_resource(ProcessCreateResource, %{body: true})
      |> test_status(200)

    assert conn.resp_body == "PUT from multipart"
  end

  test "response body with post" do
    conn =
      conn(:post, "/", "test=test")
      |> put_req_header("content-type", "mixed/multipart")
      |> call_resource(ProcessCreateResource, %{body: true})
      |> test_status(200)

    assert conn.resp_body == "POST from multipart"
  end

  test "response body with post to non-existing resource" do
    conn =
      conn(:post, "/", "test=test")
      |> put_req_header("content-type", "mixed/multipart")
      |> call_resource(ProcessCreateResource, %{exists: false, body: true})
      |> test_status(200)

    assert conn.resp_body == "POST from multipart"
  end

  test "default content type is text/html and utf-8" do
    conn(:get, "/")
    |> call_resource(IndexResource)
    |> test_header("content-type", "text/html; charset=utf-8")
  end

  test "custom content types can be provided" do
    conn(:get, "/")
    |> call_resource(JsonResource)
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")
  end

  test "media types can be represented as a binary" do
    conn(:get, "/")
    |> call_resource(BinaryCtpResource)
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")
  end

  test "content negotiation" do
    conn(:get, "/")
    |> put_req_header("accept", ",text/html,application/json")
    |> call_resource(IndexResource)
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=utf-8")

    conn(:get, "/")
    |> call_resource(IndexResource)
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=utf-8")

    conn(:get, "/")
    |> put_req_header("accept", "text/html,application/json")
    |> call_resource(HypermediaResource)
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")

    conn(:get, "/")
    |> put_req_header("accept", "application/json,text/html;q=0.9")
    |> call_resource(HypermediaResource)
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")
    |> test_header("vary", "accept-language, accept")

    conn(:get, "/")
    |> put_req_header("accept", "*/*")
    |> call_resource(HypermediaResource)
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=utf-8")

    conn(:get, "/")
    |> put_req_header("accept", "text/*")
    |> call_resource(HypermediaResource)
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=utf-8")
  end

  test "content negotiation fails" do
    conn(:get, "/")
    |> put_req_header("accept", ",text/plain")
    |> call_resource(HypermediaResource)
    |> test_status(406)
  end

  test "accept any content type" do
    conn(:post, "/accept_any", "text")
    |> put_req_header("content-type", "text/plain")
    |> call_resource(AcceptAnyResource)
    |> test_status(204)

    conn(:post, "/", "text")
    |> put_req_header("content-type", "application/json")
    |> call_resource(AcceptAnyResource)
    |> test_status(204)
  end

  test "post no content type" do
    conn(:post, "/", "text")
    |> call_resource(AcceptAnyResource)
    |> test_status(415)
  end

  test "non-matching accept-extension in accept header" do
    conn(:get, "/")
    |> put_req_header("accept", "text/html;level=2")
    |> call_resource(CtpParamsResource, %{params: %{"level" => "1"}})
    |> test_status(406)
  end

  test "no accept extension allowed in content types provided" do
    conn(:get, "/")
    |> put_req_header("accept", "text/html")
    |> call_resource(CtpParamsResource, %{params: %{}})
    |> test_status(200)
  end

  test "test no accept extension allowed, with extension" do
    conn(:get, "/no_ctp_params")
    |> put_req_header("accept", "text/html;level=2")
    |> call_resource(CtpParamsResource, %{params: %{}})
    |> test_status(406)
  end

  test "post unaccepted returns 415" do
    conn(:post, "/", "{}")
    |> put_req_header("content-type", "application/json")
    |> call_resource(AllowedMethodsResource)
    |> test_status(415)
  end

  test "post accepted content type with new location" do
    conn(:post, "/", "{}")
    |> put_req_header("content-type", "application/json; charset=utf-8")
    |> call_resource(JsonResource)
    |> test_status(303)
    |> test_header("location", "/new")
  end

  ### language negotiation

  test "language negotiation" do
    conn(:get, "/")
    |> put_req_header("accept-language", "da, en-gb;q=0.8, en;q=0.7")
    |> call_resource(LanguagesResource)
    |> test_status(200)
    |> test_header("content-language", "en")
    |> test_header("vary", "accept-language")
  end

  test "accepting all languages" do
    conn(:get, "/languages_resource")
    |> put_req_header("accept-language", "en, *")
    |> call_resource(LanguagesResource)
    |> test_status(200)
    |> test_header("content-language", "de")
    |> test_header("vary", "accept-language")
  end

  ### charset negotiation

  test "charset negotiation" do
    conn(:get, "/")
    |> put_req_header("accept-charset", "iso-8859-5, unicode-1-1;q=0.8")
    |> call_resource(CharsetResource)
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=unicode-1-1")
    |> test_header("vary", "accept-charset")
  end

  test "post accepted content type with charset" do
    conn(:post, "/", "{}")
    |> put_req_header("content-type", "application/json; charset=utf-8")
    |> call_resource(JsonResource)
    |> test_status(303)
  end

  ### resource_exists

  test "resource not exists returns 404" do
    conn(:get, "/") |> call_resource(ResourceExists, false) |> test_status(404)
  end

  ### previously_existed

  test "resource not exists, previously existed returns 404" do
    conn(:get, "/") |> call_resource(PreviouslyExisted, false) |> test_status(404)
  end

  ### moved_permanently

  test "moved permanently returns new location" do
    conn(:get, "/")
    |> call_resource(MovedPermanentlyResource)
    |> test_status(301)
    |> test_header("location", "/moved")
  end

  ### moved_temporarily

  test "moved temporarily returns new location" do
    conn(:get, "/")
    |> call_resource(MovedTemporarilyResource)
    |> test_status(307)
    |> test_header("location", "/temp")
  end

  ### gone

  test "gone returns 410" do
    conn(:get, "/") |> call_resource(GoneResource) |> test_status(410)
  end

  ### allow_missing_post

  test "default allow missing" do
    conn(:get, "/") |> call_resource(MissingPostResource, :no_call) |> test_status(404)

    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(MissingPostResource, :no_call)
    |> test_status(404)
  end

  test "allow missing" do
    conn(:get, "/") |> call_resource(MissingPostResource, true) |> test_status(404)

    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(MissingPostResource, true)
    |> test_status(204)
  end

  test "disallow missing" do
    conn(:get, "/") |> call_resource(MissingPostResource, false) |> test_status(404)

    conn(:post, "/", "test=test")
    |> put_req_header("content-type", "mixed/multipart")
    |> call_resource(MissingPostResource, false)
    |> test_status(404)
  end

  ### conditional responses

  test "if match precondition fails" do
    conn(:get, "/")
    |> put_req_header("if-match", "\"xyzzy\"")
    |> call_resource(IndexResource)
    |> test_status(412)
  end

  test "last modified" do
    conn(:get, "/")
    |> put_req_header("if-modified-since", "Sun, 17 Jul 2016 12:51:31 GMT")
    |> call_resource(LastModifiedResource)
    |> test_status(304)
  end

  test "last unmodified" do
    conn(:get, "/")
    |> put_req_header("if-unmodified-since", "Sun, 17 Jul 2016 12:51:31 GMT")
    |> put_req_header("if-none-match", "*")
    |> call_resource(LastModifiedResource)
    |> test_status(304)
  end

  test "modified undefined" do
    conn(:get, "/")
    |> put_req_header("if-modified-since", "Sun, 17 Jul 2016 12:51:31 GMT")
    |> call_resource(IndexResource)
    |> test_status(200)
  end

  test "modified nil" do
    conn(:get, "/nil_modified")
    |> put_req_header("if-modified-since", "Sun, 17 Jul 2016 12:51:31 GMT")
    |> call_resource(NilModifiedResource)
    |> test_status(200)
  end

  ### delete

  test "response body with delete" do
    conn =
      conn(:delete, "/resp_body")
      |> call_resource(ProcessCreateResource, %{body: true})
      |> test_status(200)

    assert conn.resp_body == "DELETE resource"
  end

  ### options

  test "options sends allowed methods" do
    conn(:options, "/")
    |> call_resource(IndexResource)
    |> test_status(200)
    |> test_header("allow", "HEAD, GET, OPTIONS")

    conn(:options, "/")
    |> call_resource(AllowedMethodsResource)
    |> test_status(200)
    |> test_header("allow", "HEAD, GET, POST, OPTIONS")
  end

  ### chunked body

  test "chunked body" do
    conn = conn(:get, "/") |> call_resource(ChunkedResource)

    assert conn.state == :chunked
    assert conn.status == 200

    assert conn.resp_body == "HELLOWORLD"
  end

  ### send_file body

  test "send_file body" do
    conn = conn(:get, "/") |> call_resource(SendFileResource)

    # Testing against Plug 1.3 and 1.4
    assert conn.state == :sent || conn.state == :file
    assert conn.status == 200

    assert conn.resp_body =~ "Hello World"
  end

  ### stop

  test "stop a callback with no set response" do
    conn =
      conn(:get, "/")
      |> call_resource(StopResource)
      |> test_status(204)

    assert conn.resp_body == ""
  end

  test "stop a callback with a response" do
    conn =
      conn(:get, "/")
      |> call_resource(StopResource, :resp)
      |> test_status(200)

    assert conn.resp_body == "Resp"
  end

  test "stop a callback with a send response" do
    conn =
      conn(:get, "/")
      |> call_resource(StopResource, :send)
      |> test_status(200)

    assert conn.resp_body == "Sent"
  end

  ## errors

  test "callbacks can /raise errors" do
    exception =
      assert_raise RuntimeError, fn ->
        conn(:get, "/") |> call_resource(ErrorResource)
      end

    assert Plug.Exception.status(exception) == 500
  end

  test "resource module that does not exist" do
    message = ~r/module DoesNotExistModule is not available/

    exception =
      assert_raise UndefinedFunctionError, message, fn ->
        conn(:get, "/") |> call_resource(DoesNotExistModule)
      end

    assert Plug.Exception.status(exception) == 500
  end

  ### pipeline

  test "plug pipeline in resource" do
    conn = conn(:get, "/") |> call_resource(PipelineResource)
    assert conn.resp_body == "Hello"
  end

  ### save media type

  test "save media type from request" do
    conn = conn(:get, "/") |> call_resource(IndexResource)

    assert PlugRest.Resource.get_media_type(conn) == nil

    conn = conn(:get, "/") |> call_resource(JsonResource)

    assert PlugRest.Resource.get_media_type(conn) == nil

    conn =
      conn(:get, "/")
      |> put_req_header("accept", "application/json")
      |> call_resource(JsonResource)

    assert PlugRest.Resource.get_media_type(conn) == {"application", "json", %{}}
  end

  ## Known methods option

  test "known methods option" do
    Application.put_env(:plug_rest, :known_methods, ["GET", "POST", "DELETE", "MOVE"])
    conn(:trace, "/") |> call_resource(AllowedMethodsResource) |> test_status(501)
    conn(:move, "/") |> call_resource(AllowedMethodsResource) |> test_status(405)
    Application.put_env(:plug_rest, :known_methods, nil)
  end

  test "resource overrides known methods config" do
    Application.put_env(:plug_rest, :known_methods, ["GET", "POST", "DELETE", "MOVE"])
    conn(:get, "/") |> call_resource(KnownMethodsResource) |> test_status(200)
    conn(:delete, "/") |> call_resource(KnownMethodsResource) |> test_status(501)
    conn(:trace, "/") |> call_resource(KnownMethodsResource) |> test_status(405)
    conn(:move, "/") |> call_resource(KnownMethodsResource) |> test_status(200)
    Application.put_env(:plug_rest, :known_methods, nil)
  end

  ## Resource functions

  test "REST body" do
    resp_body = "Body"

    conn =
      conn(:get, "/test")
      |> PlugRest.Resource.put_rest_body(resp_body)

    assert PlugRest.Resource.get_rest_body(conn) == resp_body
  end

  test "get unset REST body" do
    conn = conn(:get, "/test")

    assert PlugRest.Resource.get_rest_body(conn) == nil
  end

  test "media type" do
    media_type = {"text", "html", %{}}

    conn =
      conn(:get, "/test")
      |> PlugRest.Resource.put_media_type(media_type)

    assert PlugRest.Resource.get_media_type(conn) == media_type
  end

  test "get non-existent media type" do
    conn = conn(:get, "/test")

    assert PlugRest.Resource.get_media_type(conn) == nil
  end

  ## Test helpers

  defp call_resource(conn, resource, plug_opts \\ []) do
    resource.call(conn, plug_opts)
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
