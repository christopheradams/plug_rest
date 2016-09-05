# Changelog

## v0.9.0

* Enhancements
  * Don't catch exceptions raised by resource callbacks. This allows
  `Plug.Debugger` to render the errors if it's enabled.

* Backwards incompatible changes
  * For HTTP error codes, your router needs `use Plug.ErrorHandler`
  * The resource `init/2` callback will only terminate when `:stop` is
    returned. All other value will continue REST execution.
  * If the router can't find a match it will raise a `NoRouteError`.
  * Connections returning 400 or 500 will raise `RequestError` and
    `ServerError`, respectively.

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
