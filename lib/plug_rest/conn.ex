defmodule PlugRest.Conn do
  @moduledoc false

  import Plug.Conn
  import Plug.Conn.Utils

  @type conn :: Plug.Conn.t
  @type media_type    :: PlugRest.State.media_type

  @type etags_list    :: list()
  @type quality_type  :: {String.t, float()}
  @type priority_type :: {media_type, float(), map()}

  @typep params :: %{binary => binary}
  @typep maybe_media_type :: {:ok, type :: binary, subtype :: binary, params}
                           | :error

  @typep header       :: String.t
  @typep header_value :: {String.t, map()}

  @doc """
  Parses request date header as Erlang date/time tuples

  Possible headers are:
    * if-modified-since
    * if-unmodified-since

  ## Examples

      iex > PlugRest.Conn.parse_date_header(conn, "if-modified-since")
      {{2016, 7, 17}, {19, 54, 31}}

  """
  @spec parse_date_header(conn, String.t) :: [] | :calendar.time
  def parse_date_header(conn, header) do
    case get_req_header(conn, header) do
      [] ->
        []
      [date_header] ->
        try do
          date =
            date_header
            |> String.to_char_list
            |> :httpd_util.convert_request_date

          case date do
            :bad_date -> []
            date -> date
          end
        catch
          :error, :function_clause ->
            []
        end
    end
  end

  @doc """
  Parses media-type header as a {type, subtype, params} tuple

  Possible headers are:
    * content-type

  ## Examples

      iex > PlugRest.Conn.parse_media_type_header(conn, "content-type")
      {"application", "json", %{}}

  """
  @spec parse_media_type_header(conn, String.t) :: media_type | :error
  def parse_media_type_header(conn, header) do

    case get_req_header(conn, header) do
      [] ->
        :error
      [content_type] ->
        case content_type(content_type) do
          {:ok, type, subtype, params} ->

            ## Ensure that any value of charset is lowercase
            params2 = case Map.get(params, "charset") do
                        nil ->
                          params
                        charset ->
                          Map.put(params, "charset", String.downcase(charset))
                      end

            {type, subtype, params2}
          :error ->
            :error
        end
    end
  end

  @doc """
  Parses media range header into a structure that can be sorted by quality

  Possible headers are:
    * accept

  ## Examples

      iex > PlugRest.Conn.parse_media_range_header(conn, "accept")
      [{{"text", "html", %{}}, 1.0, %{}}]
  """
  @spec parse_media_range_header(conn, header) :: {:ok, [priority_type]} | :error
  def parse_media_range_header(conn, header) do
    maybe_media_types =
      get_req_header(conn, header)
      |> parse_accept_as_utils_media_type

    {media_types, status} =
      Enum.map_reduce(maybe_media_types, :ok, fn(mt, status) ->
        case mt do
          :error ->
            {:error, :error}
          {:ok, t, s, p} ->
            {{t, s, p}, status}
        end
      end)

    case status do
      :error ->
        :error
      :ok ->
        {:ok, format_media_types(media_types)}
    end
  end

  @doc """
  Parses an entity tag header into a list of etags

  Possible headers are:
    * if-match
    * if-none-match

  ## Examples
      iex > PlugRest.Conn.parse_entity_tag_header(conn, "if-none-match")
      [{:strong, "xyzzy"}]

  """
  @spec parse_entity_tag_header(conn, header) :: etags_list | :*
  def parse_entity_tag_header(conn, header) do
    case get_req_header(conn, header) do
      [] -> []
      [etags] -> :cowboy_http.entity_tag_match(etags)
    end
  end

  @doc """
  Parses other accept headers into types that can be sorted by quality

  Possible headers are:
    * accept-language
    * accept-charset

  ## Examples
      iex > PlugRest.Conn.parse_quality_header(conn, "accept-language")
      [{"da", 1.0}, {"en-gb", 0.8}, {"en", 0.7}]
  """
  @spec parse_quality_header(conn, String.t) :: [quality_type]
  def parse_quality_header(conn, header) when is_binary(header) do
    get_req_header(conn, header)
    |> parse_header
    |> reformat_tags
  end

  @spec parse_accept_as_utils_media_type([String.t]) :: [maybe_media_type]
  defp parse_accept_as_utils_media_type([]) do
    []
  end

  defp parse_accept_as_utils_media_type([accept]) when is_binary(accept) do
    accept
    |> Plug.Conn.Utils.list
    |> Enum.map(fn "*"->"*/*"; e -> e end)
    |> Enum.map(&Plug.Conn.Utils.media_type/1)
  end

  @spec format_media_types([media_type]) :: [priority_type]
  defp format_media_types(media_types) do
    media_types
    |> Enum.map(fn({type, subtype, params}) ->
      quality = case Float.parse(params["q"] || "1") do
        {q, _} -> q
        _ -> 1 end
      {{type, subtype, Map.delete(params, "q")}, quality, %{}} end)
  end

  @spec parse_header([]) :: []
  defp parse_header([]) do
    []
  end

  @spec parse_header([String.t, ...]) :: [header_value]
  defp parse_header([header]) when is_binary(header) do
    Plug.Conn.Utils.list(header)
    |> Enum.map(fn(x) ->
      {hd(String.split(x, ";")), Plug.Conn.Utils.params(x)}
    end)
  end

  @spec reformat_tags([header_value]) :: [quality_type]
  defp reformat_tags(tags) do
    tags
    |> Enum.map(fn({tag, params}) ->
      quality = case Float.parse(params["q"] || "1") do
        {q, _} -> q
        _ -> 1 end
      {tag, quality} end)
  end
end
