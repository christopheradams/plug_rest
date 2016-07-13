defmodule PlugRest.Utils do

  def print_media_type(media_type) when is_binary(media_type) do
    media_type
  end

  def print_media_type(media_type) when is_list(media_type) do
    List.to_string(media_type)
  end

  def print_media_type({type, subtype, _params}) do
    "#{type}/#{subtype}"
  end
end

