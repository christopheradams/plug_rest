defmodule PlugRest.ResourceError do
  @moduledoc """
  Raised for Resource errors

  The exception takes an atom describing the error status as detailed
  in `Plug.Conn.Status`, and an optional error message.
  """

  defexception [:message, plug_status: 500]

  def exception(args) when is_list(args) do
    # Use `keyfind` to work around type error when using Keyword on args
    {:status, status} =
      List.keyfind(args, :status, 0, {:status, :internal_server_error})
    {:message, message} =
      List.keyfind(args, :message, 0, {:message, status})
    code = Plug.Conn.Status.code(status)

    %PlugRest.ResourceError{message: message, plug_status: code}
  end
end
