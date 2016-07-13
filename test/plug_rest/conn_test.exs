defmodule PlugRest.ConnTest do
  use ExUnit.Case
  use Plug.Test

  import PlugRest.Conn

  test "parse non-existent header" do
    headers = conn(:get, "/")
    |> parse_req_header("accept-language")

    assert headers == []
  end

  test "parse content type accept header" do
    accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;err"

    actual_media_types = conn(:get, "/")
    |> put_req_header("accept", accept)
    |> parse_req_header("accept")

    expected_media_types = [{{"text", "html", %{}}, 1.0, %{}},
      {{"application", "xhtml+xml", %{}}, 1.0, %{}},
      {{"application", "xml", %{"q" => "0.9"}}, 0.9, %{}},
      {{"*", "*", %{"q" => "0.8"}}, 0.8, %{}}]

    assert actual_media_types == expected_media_types
  end

  test "parse language accept header" do
    accept = "da, en-gb;q=0.8, en;q=0.7"

    actual_headers = conn(:get, "/")
    |> put_req_header("accept-language", accept)
    |> parse_req_header("accept-language")

    expected_headers = [{"da", 1.0}, {"en-gb", 0.8}, {"en", 0.7}]

    assert actual_headers == expected_headers
  end

  test "parse charset accept header" do
    accept = "iso-8859-5, unicode-1-1;q=0.8"

    actual_headers = conn(:get, "/")
    |> put_req_header("accept-charset", accept)
    |> parse_req_header("accept-charset")

    expected_headers = [{"iso-8859-5", 1.0}, {"unicode-1-1", 0.8}]

    assert actual_headers == expected_headers
  end

  test "parse if-match header" do
    if_match = "\"xyzzy\""

    actual_headers = conn(:get, "/")
    |> put_req_header("if-match", if_match)
    |> parse_req_header("if-match")

    expected_headers = ["\"xyzzy\""]

    assert actual_headers == expected_headers
  end

  test "parse multiple if-match values" do
    if_match = "\"xyzzy\", \"r2d2xxxx\", \"c3piozzzz\""

    actual_headers = conn(:get, "/")
    |> put_req_header("if-match", if_match)
    |> parse_req_header("if-match")

    expected_headers = ["\"xyzzy\",", "\"r2d2xxxx\",", "\"c3piozzzz\""]

    assert actual_headers == expected_headers
  end

  test "parse wildcard if-match" do
    if_match = "*"

    actual_headers = conn(:get, "/")
    |> put_req_header("if-match", if_match)
    |> parse_req_header("if-match")

    expected_headers = [:*]

    assert actual_headers == expected_headers
  end
end

