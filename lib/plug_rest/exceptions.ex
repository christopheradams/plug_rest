defmodule PlugRest.ResourceError do
  @moduledoc """
  Raised for Resource errors

  The exception takes an atom describing the error status as detailed
  in `Plug.Conn.Status`, and an optional error message.
  """

  defexception [:message, plug_status: 500]

  def exception(args) when is_list(args) do
    # Force dialyzer to treat args as Keyword.t rather than `[{atom(),_}]`
    args = Keyword.new(args)

    status = Keyword.get(args, :status, :internal_server_error)
    message = Keyword.get(args, :message, status)
    code = Plug.Conn.Status.code(status)

    %PlugRest.ResourceError{message: message, plug_status: code}
  end
end
