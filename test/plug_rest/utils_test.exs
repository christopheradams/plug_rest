defmodule PlugRest.UtilsTest do
  use ExUnit.Case
  import PlugRest.Utils

  test "parses empty accept header as empty list" do
    assert parse_accept_header([]) == []
  end

  test "parses complex accept header into separate media types" do
    accept = ["text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;err"]

    actual_media_types = parse_accept_header(accept)
    expected_media_types = [{"text", "html", %{}},
                            {"application", "xhtml+xml", %{}},
                            {"application", "xml", %{"q" => "0.9"}},
                            {"*", "*", %{"q" => "0.8"}}]

    assert actual_media_types == expected_media_types
  end

  test "reformats acccept header into format that can be prioritized by cowboy_rest" do
    accept = ["text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;"]

    actual_types = accept |> parse_accept_header |> reformat_media_types_for_cowboy_rest
    expected_types = [{{"text", "html", %{}}, 1.0, %{}},
      {{"application", "xhtml+xml", %{}}, 1.0, %{}},
      {{"application", "xml", %{"q" => "0.9"}}, 0.9, %{}},
      {{"*", "*", %{"q" => "0.8"}}, 0.8, %{}}]

    assert actual_types == expected_types
  end

  test "prints media type binary to string" do
    media_type = "text/html"

    assert PlugRest.Utils.print_media_type(media_type) == media_type
  end

  test "prints media type list to string" do
    media_type = "text/html;charset=utf-8"
    mt_list = [["text", "/", "html", ""], ";charset=", "utf-8"]

    assert PlugRest.Utils.print_media_type(mt_list) == media_type
  end

  test "prints media type tuple to string" do
    media_type = "text/html"

    {:ok, type, subtype, params} = Plug.Conn.Utils.media_type(media_type)

    assert PlugRest.Utils.print_media_type({type, subtype, params}) == media_type
  end

  test "parses empty languages header as empty list" do
    assert parse_language_header([]) == []
  end

  test "parse multiple languages in header" do
    languages = ["da, en-gb;q=0.8, en;q=0.7"]

    actual = parse_language_header(languages)
    expected = [{"da", %{}}, {"en-gb", %{"q" => "0.8"}}, {"en", %{"q" => "0.7"}}]

    assert actual == expected

  end

  test "reformats language header into format that can be prioritized by cowboy_rest" do
    languages = ["da, en-gb;q=0.8, en;q=0.7"]

    actual = languages |> parse_language_header |> reformat_languages_for_cowboy_rest
    expected = [{"da", 1.0}, {"en-gb", 0.8}, {"en", 0.7}]

    assert actual == expected
  end
end
