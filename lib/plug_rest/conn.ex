defmodule PlugRest.Conn do
  @moduledoc """
  Helper functions for parsing Plug connection request headers
  and accessing url path parameters

  """

  import Plug.Conn
  import Plug.Conn.Utils

  @type conn :: %Plug.Conn{}

  @type type :: String.t
  @type subtype :: String.t
  @type params :: any()
  @type header :: String.t

  @type media_type :: {type, subtype, params}

  @type priority_type :: {media_type, float(), map()}

  @type quality_type :: {String.t, float()}

  @type header_value :: {String.t, map()}

  @path_params_key :plug_rest_path_params
  @media_type_key :plug_rest_media_type

  @doc """
  Reads the dynamic segment values from a rest resource path

  """
  @spec read_path_params(conn, Keyword.t) :: %{binary => binary}
  def read_path_params(conn, opts \\ [])

  def read_path_params(%Plug.Conn{private: %{@path_params_key => params}},
                      _opts) do
    params
  end

  def read_path_params(_conn, _opts) do
    %{}
  end


  @doc """
  Sets the dynamic path segment values for a connection

  """
  @spec put_path_params(conn, %{binary => binary}) :: conn
  def put_path_params(conn, params) do
    put_private(conn, @path_params_key, params)
  end

  @doc """
  Returns the requested media type

  """
  @spec get_media_type(conn, Keyword.t) :: media_type | String.t
  def get_media_type(conn, opts \\ [])

  def get_media_type(%Plug.Conn{private: %{@media_type_key => media_type}},
                      _opts) do
    media_type
  end

  def get_media_type(_conn, _opts) do
    ""
  end

  @doc """
  Puts the media type in the connection

  """
  @spec put_media_type(conn, media_type) :: conn
  def put_media_type(conn, media_type) do
    put_private(conn, @media_type_key, media_type)
  end

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
      [date] ->
        date |> String.to_char_list |> :httpd_util.convert_request_date
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

  @spec parse_media_type_header(conn, String.t) :: media_type
  def parse_media_type_header(conn, header) do
    [content_type] = get_req_header(conn, header)
    {:ok, type, subtype, params} = content_type(content_type)

    ## Ensure that any value of charset is lowercase
    params2 = case Map.get(params, "charset") do
                nil ->
                  params
                charset ->
                  Map.put(params, "charset", String.downcase(charset))
    end

    {type, subtype, params2}
  end

  @doc """
  Parses media range header into a structure that can be sorted by quality

  Possible headers are:
    * accept

  ## Examples

      iex > PlugRest.Conn.parse_media_range_header(conn, "accept")
      [{{"text", "html", %{}}, 1.0, %{}}]
  """

  @spec parse_media_range_header(conn, header) :: [priority_type]
  def parse_media_range_header(conn, header) do
    get_req_header(conn, header)
    |> parse_accept_header
    |> format_media_types
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

  @spec parse_entity_tag_header(conn, header) :: list()
  def parse_entity_tag_header(conn, header) do
    case get_req_header(conn, header) do
      [] -> []
      ["*"] -> [%{}]
      [etags] ->
        etags
        |> String.split
        |> Enum.map(fn(e) ->
          {etag} = List.to_tuple(:cowboy_http.entity_tag_match(e))
          etag
        end)
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

  @spec parse_accept_header([]) :: []
  def parse_accept_header([]) do
    []
  end

  @spec parse_accept_header([String.t, ...]) :: [media_type]
  def parse_accept_header([accept]) when is_binary(accept) do
    accept
    |> Plug.Conn.Utils.list
    |> Enum.map(fn "*"->"*/*"; e -> e end)
    |> Enum.map(&Plug.Conn.Utils.media_type/1)
    |> Enum.map(fn({:ok, t, s, p}) -> {t, s, p} end)
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
