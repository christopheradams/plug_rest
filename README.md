# PlugRest

A port of Cowboy's cowboy_rest module to Plug.

PlugRest supplements `Plug.Router` with an additional `resource`
macro, which matches a URL path with a resource handler module
implementing REST semantics via a series of optional callbacks.

## Hello World

Define a router to match a path with a resource handler:

    defmodule MyRouter do
        use PlugRest.Router

        resource "/hello", HelloResource
    end

Define the resource handler and implement the optional callbacks:

    defmodule HelloResource do
        @behaviour PlugRest.Resource

        def allowed_methods(conn, state) do
            {["GET"], conn, state}
        end

        def content_types_provided(conn, state) do
            {[{{"text", "html", %{}}, :to_html}], conn, state}
        end

        def to_html(conn, state) do
            {"Hello world", conn, state}
        end
    end

To run it in an `iex` session:

    $ iex -S mix
    iex> c "path/to/my_router.ex"
    [MyRouter]
    iex> c "path/to/hello_resource.ex"
    [HelloResource]
    iex> {:ok, _} = Plug.Adapters.Cowboy.http MyRouter, []
    {:ok, #PID<...>}

Your resource will be available at `http://localhost:4000/hello`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `plug_rest` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:plug_rest, "~> 0.3.0"}]
    end
    ```

  2. Ensure `plug_rest` is started before your application:

    ```elixir
    def application do
      [applications: [:cowboy, :plug, :plug_rest]]
    end
    ```

