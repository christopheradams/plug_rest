## Changelog

## v0.3.0

* Enhancements
  * Use `Plug.Router` interntally and make match macros available
  * Make compatible with Elixir 1.2

* Bug fixes
  * Ensure that resource handler modules are loaded before use

* Backwards incompatible changes
  * Change `use PlugRest` to `use PlugRest.Router`

## v0.2.0

* Definition of a Plug router pipeline and `resource` macro
* Passes test suite designed for cowboy_rest
