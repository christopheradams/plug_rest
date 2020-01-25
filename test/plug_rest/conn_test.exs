defmodule PlugRest.ConnTest do
  use ExUnit.Case
  use Plug.Test

  import PlugRest.Conn

  test "parse content type header" do
    content_type = "application/json"

    actual_header =
      conn(:post, "/")
      |> put_req_header("content-type", content_type)
      |> parse_media_type_header("content-type")

    expected_header = {"application", "json", %{}}

    assert actual_header == expected_header
  end

  test "parse bad content type header" do
    content_type = "application"

    parsed =
      conn(:post, "/")
      |> put_req_header("content-type", content_type)
      |> parse_media_type_header("content-type")

    assert parsed == :error
  end

  test "parsing charset in content-type should return lower case" do
    content_type = "text/plain;charset=UTF-8"

    actual_header =
      conn(:post, "/")
      |> put_req_header("content-type", content_type)
      |> parse_media_type_header("content-type")

    expected_header = {"text", "plain", %{"charset" => "utf-8"}}

    assert actual_header == expected_header
  end

  test "parse content type accept header" do
    accept =
      "text/html,text/html;level=1;q=0.9,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;text/html;err"

    {:ok, actual_media_types} =
      conn(:get, "/")
      |> put_req_header("accept", accept)
      |> parse_media_range_header("accept")

    expected_media_types = [
      {{"text", "html", %{}}, 1.0, %{}},
      {{"text", "html", %{"level" => "1"}}, 0.9, %{}},
      {{"application", "xhtml+xml", %{}}, 1.0, %{}},
      {{"application", "xml", %{}}, 0.9, %{}},
      {{"*", "*", %{}}, 0.8, %{}}
    ]

    assert actual_media_types == expected_media_types
  end

  test "parse malformed accept header as media range" do
    accept = "1"

    media_range =
      conn(:get, "/")
      |> put_req_header("accept", accept)
      |> parse_media_range_header("accept")

    assert media_range == :error
  end

  test "parse language accept header" do
    accept = "da, en-gb;q=0.8, en;q=0.7"

    actual_headers =
      conn(:get, "/")
      |> put_req_header("accept-language", accept)
      |> parse_quality_header("accept-language")

    expected_headers = [{"da", 1.0}, {"en-gb", 0.8}, {"en", 0.7}]

    assert actual_headers == expected_headers
  end

  test "parse charset accept header" do
    accept = "iso-8859-5, unicode-1-1;q=0.8"

    actual_headers =
      conn(:get, "/")
      |> put_req_header("accept-charset", accept)
      |> parse_quality_header("accept-charset")

    expected_headers = [{"iso-8859-5", 1.0}, {"unicode-1-1", 0.8}]

    assert actual_headers == expected_headers
  end

  test "parse if-match header" do
    if_match = "\"xyzzy\""

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-match", if_match)
      |> parse_entity_tag_header("if-match")

    expected_headers = [{:strong, "xyzzy"}]

    assert actual_headers == expected_headers
  end

  test "parse multiple if-match values" do
    if_match = "\"xyzzy\", \"r2d2xxxx\", \"c3piozzzz\""

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-match", if_match)
      |> parse_entity_tag_header("if-match")

    expected_headers = [{:strong, "xyzzy"}, {:strong, "r2d2xxxx"}, {:strong, "c3piozzzz"}]

    assert actual_headers == expected_headers
  end

  test "parse wildcard if-match" do
    if_match = "*"

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-match", if_match)
      |> parse_entity_tag_header("if-match")

    expected_headers = :*

    assert actual_headers == expected_headers
  end

  test "parse strong if-none-match" do
    if_none_match = "\"xyzzy\""

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-none-match", if_none_match)
      |> parse_entity_tag_header("if-none-match")

    expected_headers = [{:strong, "xyzzy"}]

    assert actual_headers == expected_headers
  end

  test "parse weak if-none-match" do
    if_none_match = "W/\"xyzzy\""

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-none-match", if_none_match)
      |> parse_entity_tag_header("if-none-match")

    expected_headers = [{:weak, "xyzzy"}]

    assert actual_headers == expected_headers
  end

  test "parse if-modified-since header" do
    if_modified_since = "Sun, 17 Jul 2016 19:54:31 GMT"

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-modified-since", if_modified_since)
      |> parse_date_header("if-modified-since")

    expected_headers = {{2016, 7, 17}, {19, 54, 31}}

    assert actual_headers == expected_headers
  end

  test "parse if-unmodified-since header" do
    if_unmodified_since = "Sun, 17 Jul 2016 19:54:31 GMT"

    actual_headers =
      conn(:get, "/")
      |> put_req_header("if-unmodified-since", if_unmodified_since)
      |> parse_date_header("if-unmodified-since")

    expected_headers = {{2016, 7, 17}, {19, 54, 31}}

    assert actual_headers == expected_headers
  end

  test "parse bad date header" do
    if_unmodified_since = "bad"

    conn =
      conn(:get, "/")
      |> put_req_header("if-unmodified-since", if_unmodified_since)

    assert parse_date_header(conn, "if-unmodified-since") == []
  end
end
