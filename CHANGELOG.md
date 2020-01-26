# Changelog

## v0.14.0

* Enhancements
  * Require Plug 1.8+ and drop Cowboy dependency

## v0.13.1

* Bug fixes
  * [Mix] Fix gen.resource task for Elixir 1.9

## v0.13.1

* Bug fixes
  * [Mix] Fix gen.resource task for Elixir 1.9

## v0.13.0

* Enhancements
  * [Generator] Add `namespace` option.

## v0.12.0

* Enhancements
  * Replace `dir` option in generator task with `path` option that can set the
    target filename

## v0.11.1

* Bug fixes
  * Update plug version in mix file and README

## v0.11.0

* Enhancements
  * Make resource gen task work in umbrella projects
  * Add switch to generate resource with no tutorial comments

* Backwards incompatible changes
  * The resource `init/2` callback will send 500 for any return
    value other than `:ok`
  * Change `allow_missing_post` default to `false`
  * Require Plug 1.3

## v0.10.2

* Enhancements
  * Improve documentation of REST callbacks
  * Add documentation to resource template

* Bug fixes
  * Fix typespec for handler `state` vs `rest_state`
  * Fix spec of `content_types_accepted` callback
  * Show `nil` return type in `expires` and `generate_etag` callbacks
  * List only the functions that should be imported into each Resource

## v0.10.1

* Bug fixes
  * Fix allowed_methods in resource template

## v0.10.0

* Enhancements
  * The `resource` macro will work with any Plug module
  * Plug.Builder can be used inside Resources
  * Add `:private` and `:assigns` options to resource macro

* Backwards incompatible changes
  * The `resource` macro splits the `options` into options for the
    Plug, and options for the macro. Change `state: true, host:
    "host."` to `true, host: "host."`
  * `known_methods` defaults can be changed in the application config,
    and are no longer an option for the Router or Resource plugs
  * Require all resource handlers to be Plugs

## v0.9.1

* Bug fixes
  * Fix current time function fallback

## v0.9.0

* Enhancements
  * `Plug.Debugger` will show errors if it's used

* Backwards incompatible changes
  * The resource `init/2` callback will only terminate when `:stop` is
    returned. All other value will continue REST execution.
  * Exceptions raised inside a `PlugRest.Resource` will not be caught

## v0.8.0

* Enhancements
  * Add `known_methods` option to the Router which sets the default
    known methods for resources
  * Add Mix task to generate a resource module

* Backwards incompatible changes
  * Routers must call `match` and `dispatch` manually, so that the
    plug pipeline can work as expected
  * `PlugRest.Resource.upgrade/3` takes a list of options instead of
    just handler state

## v0.7.0

* Enhancements
  * Export overridable `init/1` and `call/2` callbacks so that each
    Resource can act as a Plug module.
  * Make dynamic path parameters available in `conn.params`
  * Handler callbacks can manually set the response body with
    `put_rest_body/2`

* Bug fixes
  * Terminate correctly when a resource callback wants to `:stop`

* Backwards incompatible changes
  * Remove `read_path_params/1` (use `conn.params` instead)
  * Move private connection accessors from `Conn` to `Resource` module
    and change the specs

## v0.6.2

* Bug fixes
  * Fix bug where setting conn.resp_body directly had no effect on output

## v0.6.1

* Bug fixes
  * Simplify resource behaviour callback typespecs

## v0.6.0

* Enhancements
  * Content handler callbacks (like `to_html`) can return `{:file,
    filename}` for the body, which will use `Plug.Conn.send_file/3` to
    send the response
  * The resource macro can restrict route matches to a specific host.

* Backwards incompatible changes
  * The default values of `expires`, `generate_etag`, and
    `last_modified` are `nil` instead of `:undefined`
  * Resource initial state is set with an option keyword list:
    `resource "/path", Handler, state: :ok`

## v0.5.4

* Bug fixes
  * Fix pattern match for accept language wildcard
  * Fix `last_modified` pattern match in `if_modified_since`

## v0.5.3

* Enhancements
  * Make current time function configurable, for testing purposes

## v0.5.2

* Bug fixes
  * Fix compiler warnings when using /glob/*_rest paths

## v0.5.1

* Enhancements
  * Save chosen media type from accept header into private conn storage

* Bug fixes
  * Fix content negotiation when media type params do not match
  * Let content types provided correctly match all or none accept-extensions
  * Ditto for content types accepted

## v0.5.0

* Enhancements
  * Send 404 response by default when no routes match

* Deprecations
  * Using `match _ do` in your Router to handle 404 responses is no
    longer necessary and will show a compiler warning when present

## v0.4.5

* Bug fixes
  * Fix specs for some resource callback return types

## v0.4.1

* Enhancements
  * Import `Plug.Conn` when using `PlugRest.Resource`

## v0.4.0

* Backwards incompatible changes
  * Dynamic path segments are no longer available in `conn.params`

## v0.3.7

* Enhancements
  * Add `using` macro to `PlugRest.Resource` that adopts the module's
    behaviour and imports `PlugRest.Conn.read_path_params/1`

## v0.3.6

* Enhancements
  * Use `PlugRest.Conn.read_path_params/1` to access values of dynamic
    segments of resource paths

* Deprecations
  * Deprecate `conn.params` for url params in favor of `read_url_params/2`

## v0.3.5

* Enhancements
  * Content provided callbacks (like `to_html`) can return `{:chunked,
    enumerable}` for the body

## v0.3.3

* Enhancements
  * Return 500 response if resource handler does not exist

## v0.3.0

* Enhancements
  * Use `Plug.Router` internally and make match macros available
  * Make compatible with Elixir 1.2

* Bug fixes
  * Ensure that resource handler modules are loaded before use

* Backwards incompatible changes
  * Change `use PlugRest` to `use PlugRest.Router`

## v0.2.0

* Definition of a Plug router pipeline and `resource` macro
* Passes test suite designed for cowboy_rest
