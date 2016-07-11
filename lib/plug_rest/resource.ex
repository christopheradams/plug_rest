defmodule PlugRest.Resource do
  import Plug.Conn

  ## REST handler callbacks.

  @callback service_available(conn, state) :: {[binary()], conn, state}
            when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [service_available: 2]

  def upgrade(conn, handler, _opts \\ []) do
    state = %{handler: handler, handler_state: %{}}
    service_available(conn, state)
  end

  defp service_available(conn, state) do
    expect(conn, state, :service_available, true, &known_methods/2, 503)
  end

  defp known_methods(conn, state) do
    respond(conn, state, 200)
  end

  @callback test(conn, state) :: {[binary()], conn, state}
            when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [test: 2]

  ## REST primitives.

  defp expect(conn, state, callback, expected, on_true, on_false) do
    case call(conn, state, callback) do
      :no_call ->
        next(conn, state, on_true)
      {:halt, conn2, handler_state} ->
        terminate(conn2, %{state | :handler_state => handler_state})
      {^expected, conn2, handler_state} ->
        next(conn2, %{state | :handler_state => handler_state}, on_true)
      {_unexpected, conn2, handler_state} ->
        next(conn2, %{state | :handler_state => handler_state}, on_false)
    end
  end

  defp call(conn, %{handler: handler, handler_state: handler_state} = state, callback) do
    case function_exported?(handler, callback, 2) do
      true ->
        try do
          apply(handler, callback, [conn, handler_state])
        catch
          class, reason ->
            error_terminate(conn, state, class, reason, callback)
        end
      false ->
        :no_call
    end
  end

  defp unsafe_call(req, %{state | :handler_state => handler_state}, callback) do
    case function_exported?(handler, callback, 2) do
      true ->
        apply(handler, callback, [req, handlerState])
      false ->
        :no_call
    end
  end

  defp next(conn, state, var_next) when is_function(var_next) do
    var_next.(conn, state)
  end

  defp next(conn, state, status_code) when is_integer(status_code) do
    respond(conn, state, status_code)
  end

  defp respond(conn, state, status_code) do
    conn |> put_status(status_code) |> terminate(state)
  end

  defp terminate(conn, _state) do
    conn |> send_resp(conn.status, "Plug REST")
  end

  defp error_terminate(conn, _state, _class, reason, _callback) do
    conn |> send_resp(500, reason)
  end
end
