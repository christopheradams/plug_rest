defmodule PlugRest.RuntimeError do
  @moduledoc """
  Raised for Runtime errors
  """

  defexception [:message, plug_status: 500]
end
