# PlugRest

A port of Cowboy's cowboy_rest module to Plug.

PlugRest supplements `Plug.Router` with an additional `resource`
macro, which matches a URL path with a resource handler module
implementing REST semantics via a series of optional callbacks.

## Hello World

Define a router to match a path with a resource handler:

```elixir
defmodule MyRouter do
  use PlugRest.Router

  resource "/hello", HelloResource
end
```

Define the resource handler and implement the optional callbacks:

```elixir
defmodule HelloResource do
  @behaviour PlugRest.Resource

  def to_html(conn, state) do
    {"Hello world", conn, state}
  end
end
```

## Installation

If starting a new project, generate a supervisor application:

    $ mix new my_app --sup

Add `PlugRest` to your project in two steps:

  1. Add `:cowboy`, `:plug`, and `:plug_rest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"},
   {:plug_rest, "~> 0.3.0"}]
end
```

  2. Add these dependencies to your applications list:

```elixir
def application do
  [applications: [:cowboy, :plug, :plug_rest]]
end
```

### Resources

Create a file at `lib/my_app/hello_resource.ex` to hold your Resource
Handler:

```elixir
defmodule MyApp.HelloResource do
  @behaviour PlugRest.Resource

  def allowed_methods(conn, state) do
    {["GET"], conn, state}
  end

  def content_types_provided(conn, state) do
    {[{"text/html", :to_html}], conn, state}
  end

  def to_html(conn, state) do
    {"Hello world", conn, state}
  end
end
```

### Router

Create a file at `lib/my_app/router.ex` to hold the Router:

```elixir
defmodule MyApp.Router do
  use PlugRest.Router

  resource "/hello", MyApp.HelloResource

  match "/match" do
    send_resp(conn, 200, "Match")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
```

The PlugRest Router adds a `resource` macro which accepts a URL path
and a Module that will handle all the callbacks on the Resource.

You can also use the `match` macros from `Plug.Router`.
In the example above, we match on all routes with `_` and return a
`404` response in case none of the above routes matched.

### Application

Finally, add the Router to your supervision tree by editing
`lib/my_app.ex`:

```elixir
    # Define workers and child supervisors to be supervised
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, MyApp.Router, [], [port: 4001])
    ]
```

### Running

Compile your application and then run it:

    $ iex -S mix

Your server will be running and the resource will be available at
"http://localhost:4001/hello".
