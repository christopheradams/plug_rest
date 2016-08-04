defmodule PlugRest do
  @moduledoc """
  This is the documentation for the PlugRest project.

  PlugRest includes an Elixir port of Cowboy's cowboy_rest module, and builds on
  top of Plug's router to help your web application dispatch requests to resource
  handler modules implementing REST semantics via a series of optional callbacks.

  To work with PlugRest, you write a module that uses `PlugRest.Router`, and one or
  more modules that use `PlugRest.Resource` to handle the requests.

  For more information on Plug see:

    * [Plug](https://hexdocs.pm/plug) - a specification and conveniences
      for composable modules in between web applications
  """

end
