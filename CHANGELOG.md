## Changelog

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
