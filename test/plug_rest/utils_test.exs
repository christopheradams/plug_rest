defmodule PlugRest.UtilsTest do
  use ExUnit.Case

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

end
