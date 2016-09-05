defmodule PlugRest.RuntimeError do
  @moduledoc """
  Raised for Runtime errors
  """

  defexception [:message, plug_status: 500]
end

defmodule PlugRest.ServerError do
  @moduledoc """
  Raised for Server errors
  """

  defexception [:message, plug_status: 500, conn: nil, handler: nil]

  def message(ex) do
    status = PlugRest.Conn.Status.status(ex.plug_status)
    "#{status} for #{ex.conn.method} #{ex.conn.request_path} " <>
      "(#{inspect ex.handler})"
  end
end

defmodule PlugRest.RequestError do
  @moduledoc """
  Raised for Request errors
  """

  defexception [:message, plug_status: 400, conn: nil, handler: nil]

  def message(exception) do
    PlugRest.ServerError.message(exception)
  end
end
