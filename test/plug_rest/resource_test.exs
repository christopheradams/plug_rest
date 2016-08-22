defmodule PlugRest.ResourceTest do
  use ExUnit.Case
  use Plug.Test

  import PlugRest.Resource

  test "REST body" do
    resp_body = "Body"
    conn = conn(:get, "/test")
    |> put_rest_body(resp_body)

    assert get_rest_body(conn) == resp_body
  end

  test "get unset REST body" do
    conn = conn(:get, "/test")

    assert get_rest_body(conn) == nil
  end

  test "media type" do
    media_type = {"text", "html", %{}}
    conn = conn(:get, "/test")
    |> put_media_type(media_type)

    assert get_media_type(conn) == media_type
  end

  test "get non-existent media type" do
    conn = conn(:get, "/test")

    assert get_media_type(conn) == nil
  end
end

