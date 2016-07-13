defmodule PlugRest.Conn do
  import Plug.Conn

  def parse_req_header(conn, header) when header == "accept" do
    get_req_header(conn, header)
    |> parse_accept_header
    |> format_media_types
  end

  def parse_req_header(conn, header) do
    get_req_header(conn, header)
    |> parse_header
    |> reformat_tags
  end

  defp parse_accept_header([]) do
    []
  end

  defp parse_accept_header([accept]) when is_binary(accept) do
    accept
    |> Plug.Conn.Utils.list
    |> Enum.map(fn "*"->"*/*"; e -> e end)
    |> Enum.map(&Plug.Conn.Utils.media_type/1)
    |> Enum.reject(fn(m) -> m == :error end)
    |> Enum.map(fn({:ok, t, s, p}) -> {t, s, p} end)
  end

  def format_media_types(media_types) do
    media_types
    |> Enum.map(fn({type, subtype, params}) ->
      quality = case Float.parse(params["q"] || "1") do
        {q, _} -> q
        _ -> 1 end
      {{type, subtype, params}, quality, %{}} end)
  end

  defp parse_header([]) do
    []
  end

  defp parse_header([header]) when is_binary(header) do
    Plug.Conn.Utils.list(header)
    |> Enum.map(fn(x) ->
      {hd(String.split(x, ";")), Plug.Conn.Utils.params(x)}
    end)
  end

  defp reformat_tags(tags) do
    tags
    |> Enum.map(fn({tag, params}) ->
      quality = case Float.parse(params["q"] || "1") do
        {q, _} -> q
        _ -> 1 end
      {tag, quality} end)
  end

end
