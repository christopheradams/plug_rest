defmodule PlugRest.Router do
  @moduledoc ~S"""
  A DSL to supplement Plug Router with a resource-oriented routing algorithm.

  It provides a macro to generate routes that dispatch to specific
  resource handlers. For example:

      defmodule MyApp.Router do
        use PlugRest.Router

        plug :match
        plug :dispatch

        resource "/pages/:page", PageResource
      end

  The `resource/4` macro accepts a request of format `"/pages/VALUE"`
  and dispatches it to `PageResource`, which must be a Plug module.

  See `PlugRest.Resource` for information on how to write a Plug module that
  implements REST semantics.

  From `Plug.Router`:

  Notice the router contains a plug pipeline and by default it requires
  two plugs: `match` and `dispatch`. `match` is responsible for
  finding a matching route which is then forwarded to `dispatch`.
  This means users can easily hook into the router mechanism and add
  behaviour before match, before dispatch or after both.

  ## Routes

      resource "/hello", HelloResource

  The example above will route any requests for "/hello" to the
  `HelloResource` module.

  A route can also specify parameters which will be available to the
  resource:

      resource "/hello/:name", HelloResource

  The value of the dynamic path segment can be read inside the
  `HelloResource` module:

      %{"name" => name} = conn.params

  Routes allow globbing, which will match the end of the route. The glob
  can be discarded:

      # matches all routes starting with /hello
      resource "/hello/*_rest", HelloResource

  Or saved as a param for the resource to read:

      # matches all routes starting with /hello and saves the rest
      resource "/hello/*rest", HelloResource

  If we make a request to "/hello/value" then `conn.params` will include:

      %{"rest" => ["value"]}

  A request to "/hello/value/extra" will populate `conn.params` with:

      %{"rest" => ["value", "extra"]}
  """

  @typedoc "A URL path"
  @type path :: String.t

  @typedoc "A Plug Module"
  @type plug :: atom

  @typedoc "Options for the Plug"
  @type plug_opts :: any

  @typedoc "Options for a Router macro"
  @type options :: list

  @doc false
  defmacro __using__(_options) do
    quote location: :keep do
      use Plug.Router
      import PlugRest.Router
      @before_compile PlugRest.Router
    end
  end


  @doc false
  defmacro __before_compile__(_env) do
    quote do
      import Plug.Router, only: [match: 2]
      match _ do
        send_resp(var!(conn), 404, "")
      end
    end
  end


  ## Resource

  @doc """
  Main API to define resource routes.

  It accepts an expression representing the path, a Plug module, the
  options for the plug, and options for the macro.

  ## Examples

      resource "/path", PlugModule, plug_options, macro_options

  ## Options

  `resource/4` accepts the following options:

    * `:host` - the host which the route should match. Defaults to `nil`,
      meaning no host match, but can be a string like "example.com" or a
      string ending with ".", like "subdomain." for a subdomain match.
    * `:private` - a map of private data to merge into the connection
    * `:assigns` - a map of data to merge into the connection

  The macro accepts options that it will pass to the Plug:

      resource "/pages/:page", PageResource, [p: 1]

  You can restrict the resource to only match requests for a specific
  host. If the plug doesn't take any options, pass an empty list as
  the third argument to the macro:

      resource "/pages/:page", PageResource, [], host: "host1.example.com"
  """
  @spec resource(path, plug, plug_opts, options) :: Macro.t
  defmacro resource(path, plug, plug_opts \\ [], options \\ []) do
    add_resource(path, plug, plug_opts, options)
  end

  ## Compiles the resource into a match macro from Plug.Router
  @spec add_resource(path, plug, plug_opts, options) :: Macro.t
  defp add_resource(path, plug, plug_opts, options) do
    {vars, _match} = Plug.Router.Utils.build_path_match(path)

    # Transform the list of path variables into a data structure that will
    # bind to real path parameters inside the macro, like:
    # `[{"bar", {:bar, [], nil}}]`. The first step creates the binding. The
    # second removes any underscored variables, since using them in the macro
    # will raise a compiler warning.
    binding =
      vars
      |> Enum.map(fn(var) -> {Atom.to_string(var), Macro.var(var, nil)} end)
      |> Enum.filter(fn({var, _macro}) -> String.at(var, 0) !== "_" end)

    host = options[:host]
    private = options[:private]

    quote do
      match unquote(path), host: unquote(host), private: unquote(private) do
        conn = var!(conn)

        conn_params =
          case conn.params do
            %Plug.Conn.Unfetched{} -> %{}
            p -> p
          end

        path_params =
          Enum.reduce(
            unquote(binding),
            %{},
            fn({k,v}, p) -> Map.put(p, k, v) end
          )

        # Save dynamic path segments into conn.params
        params = Map.merge(conn_params, path_params)
        conn = %{conn | params: params}

        # Merge assigns
        options = unquote(options)
        assigns = conn.assigns
          |> Map.merge(Keyword.get(options, :assigns, %{}))
        conn = %{conn | assigns: assigns}

        plug = unquote(plug)
        plug_opts = unquote(plug_opts)

        plug.call(conn, plug.init(plug_opts))
      end
    end
  end
end
