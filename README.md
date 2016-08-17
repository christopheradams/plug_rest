# PlugRest

<img src="https://s3.amazonaws.com/dikaio/cowboy.svg" width="90" height="90" />

[![Build Status](https://travis-ci.org/christopheradams/plug_rest.svg?branch=master)](https://travis-ci.org/christopheradams/plug_rest)
[![Hex Version](https://img.shields.io/hexpm/v/plug_rest.svg)](https://hex.pm/packages/plug_rest)

An Elixir port of Cowboy's REST sub-protocol for Plug applications.

PlugRest supplements `Plug.Router` with an additional `resource`
macro, which matches a URL path with a resource handler module
implementing REST semantics via a series of optional callbacks.

PlugRest is perfect for creating well-behaved and semantically correct
hypermedia web applications.

[Documentation for PlugRest is available on hexdocs](http://hexdocs.pm/plug_rest/).<br/>
[Source code is available on Github](https://github.com/christopheradams/plug_rest).<br/>
[Package is available on hex](https://hex.pm/packages/plug_rest).


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
  use PlugRest.Resource

  def to_html(conn, state) do
    {"Hello world", conn, state}
  end
end
```

## Why PlugRest?

> The key abstraction of information in REST is a resource. <br/>
> —Roy Fielding

[Plug](https://github.com/elixir-lang/plug) forms the foundation of
most web apps we write in Elixir, by letting us specify a pipeline of
composable modules that transform HTTP requests and responses to
define our application's behavior.

### Plug Router

Out of the box, the original Plug Router gives us a DSL in the form of
macros which generate routes:

```elixir
get "/hello" do
    send_resp(conn, 200, "world")
end
```

The router is a plug which can match on an HTTP verb and a URL path,
and dispatches the request to a function body operating on the
connection.

### Phoenix Router

A Phoenix router works similarly: it generates routes that match verbs
and paths, which dispatch to a controller "action".

```elixir
get "/hello", HelloController, :show
```

Phoenix has a few extra features that help us craft an API, such as
the `resources` macro that generates eight different verb and path
pairs, and an `accepts` plug that assists with content negotiation.

### The Problem

Plug and Phoenix ask us for a single function in which to formulate a
semantically correct HTTP response, including explicitly returning an
appropriate status code if something goes wrong (or right).

For example, if a resource does not exist, we have to implement a `404
Not Found` response in every single action pertaining to that resource.

Some types of responses are nearly closed off. For example, what happens
when we `POST` a request to the above routes? Plug Router crashes and
sends a `500 Internal Server Error`. Phoenix shrugs and says `404 Not
Found`. The correct reply, of course, is `405 Method Not Allowed`
along with a list of supported methods in the header.

In the final analysis, Plug and Phoenix help us route requests, but
it's not enough for a well-behaved API. In order words, the **rest**
is up to us. :smirk:

### The Solution

Instead of having to redefine HTTP semantics for every web application
and route, we prefer to describe our resources in a declarative way,
and let PlugRest encapsulate all of the decisions, while providing
sane defaults when the resource's behavior is undefined.

Let's see how PlugRest handles the above scenario. First we tell the
router about our resource:

```elixir
resource "/hello", HelloResource
```

And that's it! By default our resource supports `HEAD`, `GET`, and
`OPTIONS` methods. If we want to support `POST`, we implement an
`allowed_methods/2` function in our resource:

```elixir
def allowed_methods(conn, state) do
  {["HEAD", "GET", "OPTIONS", "POST"], conn, state}
end
```

The [docs](https://hexdocs.pm/plug_rest/PlugRest.Resource.html)
for `PlugRest.Resource` list all of the supported REST callbacks and
their default values.

### Is it RESTful?

PlugRest can help your Elixir application become a fluent speaker of
the HTTP protocol. It can assist with content negotiation, and let
your API reply succinctly about resource status and availability,
permissions, redirects, etc. However, it will not offer you
templating, advanced user authentication, web sockets, or database
connections. It will also not help you choose an appropriate media
type for your API, whether HTML or [JSON API](http://jsonapi.org/).

PlugRest is definitely not the first or only library to take a
resource-oriented approach to REST-based frameworks. Basho's
[Webmachine](https://github.com/webmachine/webmachine) has been a
stable standby for years, and inspired similar frameworks in many
other programming languages. PlugRest's most immediate antecedent is
the `cowboy_rest` module in the Cowboy webserver that currently
underpins Phoenix and most other Plug-based Elixir apps.

You can use PlugRest in a standalone web app or as part of an existing
Phoenix application. Details below!


## Installation

If starting a new project, generate a supervisor application:

    $ mix new my_app --sup

Add PlugRest to your project in two steps:

1. Add `:cowboy`, `:plug`, and `:plug_rest` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:cowboy, "~> 1.0.0"},
       {:plug, "~> 1.0"},
       {:plug_rest, "~> 0.6.0"}]
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
  use PlugRest.Resource

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
end
```

The PlugRest Router adds a `resource` macro which accepts a URL path
and a Module that will handle all the callbacks on the Resource.

You can also use the `match` macros from `Plug.Router`.
This provides an escape hatch to bypass the REST mechanism for a
particular route and send a Plug response manually.

If no routes match, PlugRest will send a response with a `404` status
code to the client automatically.

#### Dynamic path segments

Router paths can have segments that match URLs dynamically:

```elixir
  resource "/users/:id", MyApp.UserResource
```

The path parameters can be accessed in your resource with `read_path_params/1`:

```elixir
    def to_html(conn, state) do
      params = read_path_params(conn)
      user_id = params["id"]
      {"Hello #{user_id}", conn, state}
    end
```

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
`http://localhost:4001/hello`.

### Testing

Use `Plug.Test` to help verify your resources's responses to separate
requests. Create a file at `test/resources/hello_resource_test.exs` to
hold your test:

```elixir
defmodule MyApp.HelloResourceTest do
  use ExUnit.Case
  use Plug.Test

  alias MyApp.Router

  test "get hello resource" do
    conn = conn(:get, "/hello")

    conn = Router.call(conn, [])

    assert conn.status == 200
    assert conn.resp_body == "Hello world"
  end
end
```

Run the test with:

    $ mix test

## Phoenix

You can use PlugRest in your Phoenix app. Add `:plug_rest` to your
dependencies, save your REST router at `web/rest_router.ex`, and put
your resources in `web/resources/`. Then use the `forward` macro in
your Phoenix `web/router.ex`:

```elixir
  forward "/rest", HelloPhoenix.RestRouter
```

The resource will be served at `http://localhost:4001/rest/hello`.

## Information

The Cowboy documentation has more details on the REST protocol:

* [REST principles](https://github.com/ninenines/cowboy/blob/master/doc/src/guide/rest_principles.asciidoc)
* [REST handlers](https://github.com/ninenines/cowboy/blob/master/doc/src/guide/rest_handlers.asciidoc)
* [REST flowcharts](https://github.com/ninenines/cowboy/blob/master/doc/src/guide/rest_flowcharts.asciidoc)
* [cowboy_rest](https://github.com/ninenines/cowboy/blob/master/doc/src/manual/cowboy_rest.asciidoc)

Differences between PlugRest and cowboy_rest:

* Each callback accepts a Plug `conn` struct instead of a Cowboy `Req`
  record.
* The `init/2` callback is not required. However, if it does exist, it
  should return `{:ok, conn, state}`.
* The default values of `expires/2`, `generate_etag/2`, and
  `last_modified/2` are `nil` instead of `:undefined`
* The content callbacks (like `to_html`) return `{body, conn, state}`
  where the body is one of `binary()`, `{:chunked, Enum.t}`, or
  `{:file, binary()}`.
* Other callbacks that need to set the body on PUT, POST, or DELETE,
  can set the value of `conn.resp_body` directly before returning
  it. The body can only be a `binary()`.
* The content types provided and accepted callbacks can describe each
  media type with a String like `"text/html"`; or a tuple in the form
  `{type, subtype, params}`, where params can be `%{}` (no params
  acceptable), `:*` (all params acceptable), or a map of acceptable
  params `%{"level" => "1"}`.


### Upgrading

PlugRest is still in an initial development phase. Expect breaking
changes at least in each minor version.

See the [CHANGELOG](CHANGELOG.md) for more information.

## License

PlugRest copyright &copy; 2016, [Christopher Adams](https://github.com/christopheradams)

cowboy_rest copyright &copy; 2011-2014, Loïc Hoguin <essen@ninenines.eu>

Cowboy logo copyright &copy; 2016, [dikaio](https://github.com/dikaio)
