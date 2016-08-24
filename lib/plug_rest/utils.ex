defmodule PlugRest.Utils do
  @moduledoc false

  @doc """
  Converts media type representation to a String

  ## Examples

      iex> PlugRest.Utils.print_media_type("text/plain")
      "text/plain"

      iex> PlugRest.Utils.print_media_type({"text", "plain", %{})
      "text/plain"

  """

  @type type :: String.t
  @type subtype :: String.t
  @type params :: any()

  @type media_type :: {type, subtype, params}

  @spec print_media_type(String.t) :: String.t
  def print_media_type(media_type) when is_binary(media_type) do
    media_type
  end

  @spec print_media_type(list()) :: String.t
  def print_media_type(media_type) when is_list(media_type) do
    List.to_string(media_type)
  end

  @spec print_media_type(media_type) :: String.t
  def print_media_type({type, subtype, _params}) do
    "#{type}/#{subtype}"
  end
end

