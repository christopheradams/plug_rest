# PlugRest

<img src="https://s3.amazonaws.com/dikaio/cowboy.svg" width="90" height="90" />

[![Build Status](https://travis-ci.org/christopheradams/plug_rest.svg?branch=master)](https://travis-ci.org/christopheradams/plug_rest)
[![Hex Version](https://img.shields.io/hexpm/v/plug_rest.svg)](https://hex.pm/packages/plug_rest)

An Elixir port of Cowboy's REST sub-protocol for Plug applications.

PlugRest has two main components:

* `PlugRest.Router` - supplements Plug's router with a `resource` macro,
  which matches a URL path with a Plug module for all HTTP methods
* `PlugRest.Resource` - defines a behaviour for Plug modules to
  represent web resources declaratively using multiple callbacks

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

  plug :match
  plug :dispatch

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

### Plug and Phoenix

If we want to route our incoming requests, we can use either Plug
Router or Phoenix. Plug Router matches an HTTP verb with a path, and
executes a block of code that operates on the connection and sends a
response:

```elixir
get "/hello", do: send_resp(conn, 200, "world")
```

Similarly, Phoenix's router matches a verb with a path, and dispatches
to another plug (normally, a Controller):

```elixir
get "/hello", HelloController, :show
```

### The Problem

Neither Plug Router nor Phoenix fully capture the concept of a
"resource" as it is known in REST and HTTP semantics.

For example, clients should be able to query the resource using
`OPTIONS` to find out what methods are allowed. In Phoenix, we would
have to define an `options` route for every single path, and send the
correct response manually.

If a client accesses a resource using a method that is not allowed,
the web application should let it know about the error and list which
methods are allowed. However, since Phoenix considers a route to be a
verb plus a path, the Router will fail to find a match and reply `404
Not Found`.

If we want better API behavior, we have to look up and explicitly
return the appropriate status codes if something goes wrong (or
right), and we have to do it for every single Controller action. This
is both fragile and error-prone.

### The Solution

Instead of having to redefine HTTP semantics for every web application
and route, we prefer to describe our resources in a declarative way,
and let PlugRest encapsulate all of the decisions, while providing
sane defaults when the resource's behavior is undefined.

PlugRest knows how to respond to `OPTIONS` requests automatically, out
of the box, for every resource. It uses the same information to handle
unsupported HTTP methods by sending a `405 Method Not Allowed` error
along with the list of correct methods in the header.

PlugRest can deal with many other potential resource statuses, and get
it right every single time.

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

```sh
$ mix new my_app --sup
```

Add PlugRest to your project in two steps:

1. Add `:cowboy`, `:plug`, and `:plug_rest` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:cowboy, "~> 1.0.0"},
       {:plug, "~> 1.0"},
       {:plug_rest, "~> 0.10.0"}]
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
    {"Hello #{state}", conn, state}
  end
end
```

### Router

Create a file at `lib/my_app/router.ex` to hold the Router:

```elixir
defmodule MyApp.Router do
  use PlugRest.Router
  use Plug.ErrorHandler

  plug :match
  plug :dispatch

  resource "/hello", MyApp.HelloResource, "World"

  match "/match" do
    send_resp(conn, 200, "Match")
  end
end
```

The PlugRest Router adds a `resource` macro which accepts a URL path,
a Plug module, and its options. If the module is a `PlugRest.Resource`,
it will begin executing the REST callbacks, passing in any initial
`state` given to it.

The router contains a plug pipeline and requires two plugs: `match`
and `dispatch`. You can add custom plugs into this pipeline.

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

The path parameters can be accessed in your resource in `conn.params`:

```elixir
def to_html(%{params: params} = conn, state) do
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

```sh
$ iex -S mix
```

Your server will be running and the resource will be available at
`http://localhost:4001/hello`.

### Tasks

You can generate a new PlugRest resource (with all of the callbacks
implemented) by using a Mix task:

```sh
$ mix plug_rest.gen.resource UserResource
```


## Usage

### Callbacks

The `PlugRest.Resource` module defines dozens of callbacks that offer
a declarative strategy for defining a resource's behavior. Implement
your desired callbacks and let this library *do the REST*, including
returning the appropriate response headers and status code.

Each callback takes two arguments:

* `conn` - a `%Plug.Conn{}` struct; use this to fetch details about
  the request (see the Plug docs for more info)
* `state` - the state of the Resource; use this to store any data that
  should be availble to subsequent callbacks

Each callback must return a three-element tuple of the form `{value,
conn, state}`. All callbacks are optional, and will be given default
values if you do not define them. Some of the most common and useful
callbacks are shown below with their defaults:

      allowed_methods        : ["GET", "HEAD", "OPTIONS"]
      content_types_accepted : none
      content_types_provided : [{{"text/html"}, :to_html}]
      forbidden              : false
      is_authorized          : true
      last_modified          : nil
      malformed_request      : false
      moved_permanently      : false
      moved_temporarily      : false
      resource_exists        : true

The [docs](https://hexdocs.pm/plug_rest/PlugRest.Resource.html)
for `PlugRest.Resource` list all of the supported REST callbacks and
their default values.

### Content Negotiation

#### Content Types Provided

You can return representations of your resource in different formats
by implementing the `content_types_provided` callback, which pairs
each content-type with a handler function:

```elixir
def content_types_provided(conn, state) do
  {[{"text/html", :to_html},
    {"application/json", :to_json}], conn, state}
end

def to_html(conn, state) do
  {"<h1>Hello</h1>", conn, state}
end

def to_json(conn, state) do
  {"{\"title\": \"Hello\"}", conn, state}
end
```

#### Content Types Accepted

Similarly, you can accept different media types from clients by
implementing the `content_types_accepted` callback:

```elixir
def content_types_accepted(conn, state) do
  {[{"mixed/multipart", :from_multipart},
    {"application/json", :from_json}], conn, state}
    end

def from_multipart(conn, state) do
  # fetch or read the request body params, update the database, etc.
  {true, conn, state}
end

def from_json(conn, state) do
  {true, conn, state}
end
```

The content handler functions you implement can return either `true`,
`{true, URL}` (for redirects), or `false` (for errors). Don't forget
to add "POST", "PUT", and/or "PATCH" to your resources's list of
`allowed_methods`.

Consult the `Plug.Conn` and `Plug.Parsers` docs for information on
parsing and reading the request body params.

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

```sh
$ mix test
```

### Debugging

To help debug your app during development, add `Plug.Debugger` to the
top of the router, before `use Plug.ErrorHandler`:

```elixir
defmodule MyApp.Router do
  use PlugRest.Router

  if Mix.env == :dev do
    use Plug.Debugger, otp_app: :my_app
  end

  use Plug.ErrorHandler

  # ...
end
```

### Error Handling

By adding `use Plug.ErrorHandler` to your router, you will ensure it
returns correct HTTP status codes when plugs raise exceptions. To set
a custom error response, add the `handle_errors/2` callback to your
router:

```elixir
defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
  send_resp(conn, conn.status, "Something went wrong")
end
```


## Phoenix

You can use PlugRest's router and resources in your Phoenix app like
any other plug by forwarding requests to them:

```elixir
forward "/rest", HelloPhoenix.RestRouter
```

To get the `resource` macro directly in your Phoenix router, use
[PhoenixRest](https://github.com/christopheradams/phoenix_rest/).


## Information

The Cowboy documentation has more details on the REST protocol:

* [REST principles](http://ninenines.eu/docs/en/cowboy/2.0/guide/rest_principles/)
* [Handling REST requests](http://ninenines.eu/docs/en/cowboy/2.0/guide/rest_handlers/)
* [REST flowcharts](http://ninenines.eu/docs/en/cowboy/2.0/guide/rest_flowcharts/)
* [Designing a resource handler](http://ninenines.eu/docs/en/cowboy/2.0/guide/resource_design/)
* [Function Reference: cowboy_rest](http://ninenines.eu/docs/en/cowboy/2.0/manual/cowboy_rest/)

Differences between PlugRest and cowboy_rest:

* Each callback accepts a Plug `conn` struct instead of a Cowboy `Req`
  record.
* The `init/2` callback is not required.
* The default values of `expires/2`, `generate_etag/2`, and
  `last_modified/2` are `nil` instead of `:undefined`
* The content callbacks (like `to_html`) return `{body, conn, state}`
  where the body is one of `binary()`, `{:chunked, Enum.t}`, or
  `{:file, binary()}`.
* Other callbacks that need to set the body on PUT, POST, or DELETE,
  can use `put_rest_body/2` taking `(conn, body)` before returning
  it. The body can only be a `binary()`.
* The content types provided and accepted callbacks can describe each
  media type with a String like `"text/html"`; or a tuple in the form
  `{type, subtype, params}`, where params can be `%{}` (no params
  acceptable), `:*` (all params acceptable), or a map of acceptable
  params `%{"level" => "1"}`.
* Exceptions raised by a resource are not caught, but instead allowed
  to bubble up to Plug's Debugger or ErrorHandler if they are
  available.

### Upgrading

PlugRest is still in an initial development phase. Expect breaking
changes at least in each minor version.

See the [CHANGELOG](CHANGELOG.md) for more information.


## License

PlugRest copyright &copy; 2016, [Christopher Adams](https://github.com/christopheradams)

cowboy_rest copyright &copy; 2011-2014, Loïc Hoguin <essen@ninenines.eu>

Cowboy logo copyright &copy; 2016, [dikaio](https://github.com/dikaio)
