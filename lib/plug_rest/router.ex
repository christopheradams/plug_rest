defmodule PlugRest.Router do

  @moduledoc """
  A DSL to supplement Plug Router with a resource-oriented routing algorithm.
  """

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      use Plug.Router
      import PlugRest.Router

      plug :match
      plug :dispatch
    end
  end

  defmacro resource(path, handler, handler_state \\ []) do
    add_resource(path, handler, handler_state)
  end

  defp add_resource(path, handler, handler_state) do
    {vars, _match} = Plug.Router.Utils.build_path_match(path)

    binding = for var <- vars do
      {Atom.to_string(var), Macro.var(var, nil)}
    end

    quote do
      match unquote(path) do

        params =
          Enum.reduce(
            unquote(binding),
            %{},
            fn({k,v}, p) -> Map.put(p, k, v) end
          )

        # Save dynamic path segments into private connection storage
        conn2 = var!(conn) |> put_private(:plug_rest_path_params, params)

        PlugRest.Resource.upgrade(conn2, unquote(handler), unquote(handler_state))
      end
    end
  end
end
