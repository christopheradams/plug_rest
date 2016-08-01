defmodule PlugRest.RouterTest do
  use ExUnit.Case
  use Plug.Test

  defmodule IndexResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      {"Plug REST", conn, state}
    end
  end

  defmodule ServiceAvailableResource do
    use PlugRest.Resource

    def service_available(conn, false = state) do
      {false, conn, state}
    end

    def to_html(conn, state) do
      {"Service Available", conn, state}
    end
  end

  defmodule KnownMethodsResource do
    use PlugRest.Resource

    def known_methods(conn, state) do
      {["GET", "POST"], conn, state}
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
      {:true, conn, state}
    end
  end

  defmodule DeleteResource do
    use PlugRest.Router

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

  defmodule JsonResource do
    use PlugRest.Resource

    def allowed_methods(conn, state) do
      {["GET", "POST"], conn, state}
    end

    def content_types_provided(conn, state) do
      {[{{"application", "json", %{}}, :to_json}], conn, state}
    end

    def content_types_accepted(conn, state) do
      {[{{"application", "json", %{}}, :from_json}], conn, state}
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
      {[{{"text", "html", %{}}, :to_html},
        {{"application", "json", %{}}, :to_json}
      ], conn, state}
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

  defmodule UserCommentResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      params = read_path_params(conn)
      user_id = params["user_id"]
      comment_id = params["comment_id"]

      {"#{user_id} : #{comment_id}", conn, state}
    end
  end

  defmodule ChunkedResource do
    use PlugRest.Resource

    def to_html(conn, state) do
      body = ["HELLO", "WORLD"]
      {{:chunked, body}, conn, state}
    end
  end

  defmodule RestRouter do
    use PlugRest.Router

    resource "/", IndexResource
    resource "/service_unavailable", ServiceAvailableResource, false
    resource "/known_methods", KnownMethodsResource
    resource "/uri_too_long", UriTooLongResource
    resource "/allowed_methods", AllowedMethodsResource
    resource "/malformed_request", MalformedRequestResource
    resource "/unauthorized", UnauthorizedResource
    resource "/forbidden", ForbiddenResource
    resource "/invalid_content_headers", InvalidContentHeadersResource
    resource "/invalid_entity_length", InvalidEntityLengthResource
    resource "/conflict", ConflictResource
    resource "/delete", DeleteResource
    resource "/json_resource", JsonResource
    resource "/hypermedia_resource", HypermediaResource
    resource "/content_negotiation", HypermediaResource
    resource "/binary_ctp_resource", BinaryCtpResource
    resource "/languages_resource", LanguagesResource
    resource "/charset_resource", CharsetResource
    resource "/resource_not_exists", ResourceExists, false
    resource "/previously_existed", PreviouslyExisted, false
    resource "/moved_permanently", MovedPermanentlyResource
    resource "/moved_temporarily", MovedTemporarilyResource
    resource "/gone", GoneResource
    resource "/last_modified", LastModifiedResource

    resource "/does_not_exist", DoesNotExistModule

    resource "/users/:user_id/comments/:comment_id", UserCommentResource

    resource "/chunked", ChunkedResource

    match "/match" do
      send_resp(conn, 200, "Matches!")
    end
  end

  test "basic DSL is available" do
    conn = conn(:get, "/")

    conn = RestRouter.call(conn, [])

    test_status(conn, 200)
    assert conn.resp_body == "Plug REST"
  end

  test "match can match known route" do
    conn = build_conn(:get, "/match")
    |> test_status(200)

    assert conn.resp_body == "Matches!"
  end

  test "match any can catch unknown route" do
    conn = build_conn(:get, "/unknown")
    |> test_status(404)

    assert conn.resp_body == ""
  end

  test "resource module that does not exist returns 500" do
    build_conn(:get, "/does_not_exist") |> test_status(500)
  end

  test "service unavailable returns 503" do
    build_conn(:get, "/service_unavailable") |> test_status(503)
  end

  test "unknown method returns 501" do
    build_conn(:delete, "/known_methods") |> test_status(501)
  end

  test "uri too long returns 414" do
    build_conn(:get, "/uri_too_long") |> test_status(414)
  end

  test "unallowed method returns 405" do
    build_conn(:delete, "/allowed_methods") |> test_status(405)
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

  test "put when conflict" do
    build_conn(:put, "/conflict") |> test_status(409)
  end

  test "delete resource" do
    build_conn(:delete, "/delete?completed=true") |> test_status(204)
  end

  test "delete not completed" do
    build_conn(:delete, "/delete?completed=false") |> test_status(202)
  end

  test "options sends allowed methods" do
    conn = build_conn(:options, "/")
    test_status(conn, 200)
    test_header(conn, "allow", "HEAD, GET, OPTIONS")

    conn2 = build_conn(:options, "/allowed_methods")
    test_status(conn2, 200)
    test_header(conn2, "allow", "HEAD, GET, POST, OPTIONS")
  end

  test "default content type is text/html and utf-8" do
    build_conn(:get, "/")
    |> test_header("content-type", "text/html; charset=utf-8")
  end

  test "custom content types can be provided" do
    build_conn(:get, "/json_resource")
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")
  end

  test "media types can be represented as a binary" do
    build_conn(:get, "/binary_ctp_resource")
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")
  end

  test "content negotiation" do
    conn(:get, "/")
    |> put_req_header("accept", ",text/html,application/json")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=utf-8")

    build_conn(:get, "/content_negotiation")
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=utf-8")

    conn(:get, "/content_negotiation")
    |> put_req_header("accept", "text/html,application/json")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")

    conn(:get, "/content_negotiation")
    |> put_req_header("accept", "application/json,text/html;q=0.9")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_header("content-type", "application/json; charset=utf-8")
    |> test_header("vary", "accept-language, accept")
  end

  test "content negotiation fails" do
    conn(:get, "/content_negotiation")
    |> put_req_header("accept", ",text/plain")
    |> RestRouter.call([])
    |> test_status(406)
  end

  test "language negotiation" do
    conn(:get, "/languages_resource")
    |> put_req_header("accept-language", "da, en-gb;q=0.8, en;q=0.7")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_header("content-language", "en")
    |> test_header("vary", "accept-language")
  end

  test "charset negotiation" do
    conn(:get, "/charset_resource")
    |> put_req_header("accept-charset", "iso-8859-5, unicode-1-1;q=0.8")
    |> RestRouter.call([])
    |> test_status(200)
    |> test_header("content-type", "text/html; charset=unicode-1-1")
    |> test_header("vary", "accept-charset")
  end

  test "post unaccepted returns 415" do
    conn(:post, "/allowed_methods", "{}")
    |> put_req_header("content-type", "application/json")
    |> RestRouter.call([])
    |> test_status(415)
  end

  test "post accepted content type with new location" do
    conn(:post, "/json_resource", "{}")
    |> put_req_header("content-type", "application/json")
    |> RestRouter.call([])
    |> test_status(303)
    |> test_header("location", "/new")
  end

  test "resource not exists returns 404" do
    build_conn(:get, "/resource_not_exists") |> test_status(404)
  end

  test "resource not exists, previously existed returns 404" do
    build_conn(:get, "/previously_existed") |> test_status(404)
  end

  test "moved permanently returns new location" do
    build_conn(:get, "/moved_permanently") |> test_status(301)
    |> test_header("location", "/moved")
  end

  test "moved temporarily returns new location" do
    build_conn(:get, "/moved_temporarily") |> test_status(307)
    |> test_header("location", "/temp")
  end

  test "gone returns 410" do
    build_conn(:get, "/gone") |> test_status(410)
  end

  test "if match precondition fails" do
    conn(:get, "/")
    |> put_req_header("if-match", "\"xyzzy\"")
    |> RestRouter.call([])
    |> test_status(412)
  end

  test "last modified" do
    conn(:get, "/last_modified")
    |> put_req_header("if-modified-since", "Sun, 17 Jul 2016 12:51:31 GMT")
    |> RestRouter.call([])
    |> test_status(304)
  end

  test "last unmodified" do
    conn(:get, "/last_modified")
    |> put_req_header("if-unmodified-since", "Sun, 17 Jul 2016 12:51:31 GMT")
    |> put_req_header("if-none-match", "*")
    |> RestRouter.call([])
    |> test_status(304)
  end

  test "dynamic path populates connection params" do
    conn = conn(:get, "/users/1234/comments/987")
    |> RestRouter.call([])

    test_status(conn, 200)
    assert conn.resp_body == "1234 : 987"
  end

  test "chunked body" do
    conn = build_conn(:get, "/chunked")

    assert conn.state == :chunked
    assert conn.status == 200

    assert conn.resp_body == "HELLOWORLD"
  end

  test "save media type from request" do
    conn = conn(:get, "/")
    |> RestRouter.call([])

    assert PlugRest.Conn.get_media_type(conn) == ""

    conn = conn(:get, "/json_resource")
    |> RestRouter.call([])

    assert PlugRest.Conn.get_media_type(conn) == ""

    conn = conn(:get, "/json_resource")
    |> put_req_header("accept", "application/json")
    |> RestRouter.call([])

    assert PlugRest.Conn.get_media_type(conn) == {"application", "json", %{}}
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
end
