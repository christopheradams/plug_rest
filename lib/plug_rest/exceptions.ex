defmodule PlugRest.ResourceError do
  @moduledoc """
  Raised for Resource errors

  The exception takes an atom describing the error status as detailed
  in `Plug.Conn.Status`, and an optional error message.
  """

  defexception [:message, :plug_status]

  def exception([status: status]) do
    exception([status: status, message: status])
  end

  def exception([status: status, message: message]) do
    code = Plug.Conn.Status.code(status)
    %PlugRest.ResourceError{message: message, plug_status: code}
  end
end
