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

  defmacro resource(path, handler, handler_state \\ []) do
    add_route(path, handler, handler_state)
  end

  defp add_route(path, handler, handler_state) do
    {vars, match} = Plug.Router.Utils.build_path_match(path)

    binding = for var <- vars do
      {Atom.to_string(var), Macro.var(var, nil)}
    end

    quote do
      defp do_match(conn, unquote(match)) do

        params =
          case conn.params do
            %Plug.Conn.Unfetched{} -> %{}
            p -> p
          end

        # Save any dynamic path segments into conn.params key/value pairs
        params2 =
          Enum.reduce(
            unquote(binding),
            params,
            fn({k,v}, p) -> Map.put(p, k, v) end
          )

        conn2 = %{conn | params: params2}

        PlugRest.Resource.upgrade(conn2, unquote(handler), unquote(handler_state))
      end
    end
  end
end
