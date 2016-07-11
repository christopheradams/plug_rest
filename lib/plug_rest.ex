defmodule PlugRest do

  @moduledoc """
  A DSL to define a resource-oriented REST Plug.
  """

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      use Plug.Builder
      import PlugRest

      plug :rest

      defp rest(%{path_info: path_info} = conn, opts) do
        do_match(conn, Enum.map(conn.path_info, &URI.decode/1))
      end
    end
  end

  defmacro resource(path, handler) do
    add_route(path, handler)
  end

  defp add_route(path, _handler) do
    {_vars, match} = Plug.Router.Utils.build_path_match(path)
    quote do
      defp do_match(conn, unquote(match)) do
        conn |> put_resp_content_type("text/html") |> send_resp(200, "Plug REST")
      end
    end
  end
end
