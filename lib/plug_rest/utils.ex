defmodule PlugRest.Utils do

  def parse_accept_header([]) do
    []
  end

  def parse_accept_header([accept]) when is_binary(accept) do
    accept
    |> Plug.Conn.Utils.list
    |> Enum.map(fn "*"->"*/*"; e -> e end)
    |> Enum.map(&Plug.Conn.Utils.media_type/1)
    |> Enum.reject(fn(m) -> m == :error end)
    |> Enum.map(fn({:ok, t, s, p}) -> {t, s, p} end)
  end

  def reformat_media_types_for_cowboy_rest(media_types) do
    media_types
    |> Enum.map(fn({type, subtype, params}) ->
      quality = case Float.parse(params["q"] || "1") do
        {q, _} -> q
        _ -> 1 end
      {{type, subtype, params}, quality, %{}} end)
  end

  def print_media_type(media_type) when is_binary(media_type) do
    media_type
  end

  def print_media_type(media_type) when is_list(media_type) do
    List.to_string(media_type)
  end

  def print_media_type({type, subtype, _params}) do
    "#{type}/#{subtype}"
  end

  def parse_language_header([]) do
    []
  end

  def parse_language_header([languages]) when is_binary(languages) do
    Plug.Conn.Utils.list(languages)
    |> Enum.map(fn(x) ->
      {hd(String.split(x, ";")), Plug.Conn.Utils.params(x)}
    end)
  end

  def reformat_languages_for_cowboy_rest(languages) do
    languages
    |> Enum.map(fn({tag, params}) ->
      quality = case Float.parse(params["q"] || "1") do
        {q, _} -> q
        _ -> 1 end
      {tag, quality} end)
  end
end

