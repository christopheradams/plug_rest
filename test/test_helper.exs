defmodule PlugRest.TestHelper do
  defmacro build_resource(resource, callbacks) do

    functions = for {callback, value} <- callbacks do
      quote do
        def unquote(callback)(conn, state) do
          {unquote(value), conn, state}
        end
      end
    end

    quote do
      defmodule unquote(resource) do
        use PlugRest.Resource

        unquote(functions)
      end
    end
  end
end

ExUnit.start()
