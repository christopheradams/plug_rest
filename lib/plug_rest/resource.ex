defmodule PlugRest.Resource do
  import Plug.Conn

  ## REST handler callbacks.

  @callback allowed_methods(conn, state) :: {[binary()], conn, state}
                                          | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [allowed_methods: 2]

  @callback allow_missing_post(conn, state) :: {boolean(), conn, state}
                                             | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [allow_missing_post: 2]

  @callback charsets_provided(conn, state) :: {[binary()], conn, state}
                                            | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [charsets_provided: 2]

  @callback content_types_accepted(conn, state) :: {[{binary() | {binary(), binary(), '*' | [{binary(), binary()}]}, atom()}], conn, state}
                                                 | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [content_types_accepted: 2]

  @callback content_types_provided(conn, state) :: {[{binary() | {binary(), binary(), '*' | [{binary(), binary()}]}, atom()}], conn, state}
                                                 | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [content_types_provided: 2]

  @callback delete_completed(conn, state) :: {boolean(), conn, state}
                                           | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [delete_completed: 2]

  @callback delete_resource(conn, state) :: {boolean(), conn, state}
                                          | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [delete_resource: 2]

  @callback expires(conn, state) :: {:calendar.datetime() | binary() | :undefined, conn, state}
                                  | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [expires: 2]

  @callback forbidden(conn, state) :: {boolean(), conn, state}
                                    | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [forbidden: 2]

  @callback generate_etag(conn, state) :: {binary() | {:weak | :strong, binary()}, conn, state}
                                        | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [generate_etag: 2]

  @callback is_authorized(conn, state) :: {true | {false, iodata()}, conn, state}
                                        | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [is_authorized: 2]

  @callback is_conflict(conn, state) :: {boolean(), conn, state}
                                      | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [is_conflict: 2]

  @callback known_methods(conn, state) :: {[binary()], conn, state}
                                        | {:stop, conn, state}
            when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [known_methods: 2]

  @callback languages_provided(conn, state) :: {[binary()], conn, state}
                                             | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [languages_provided: 2]

  @callback last_modified(conn, state) :: {:calendar.datetime(), conn, state}
                                        | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [last_modified: 2]

  @callback malformed_request(conn, state) :: {boolean(), conn, state}
                                            | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [malformed_request: 2]

  @callback moved_permanently(conn, state) :: {{true, iodata()} | false, conn, state}
                                            | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [moved_permanently: 2]

  @callback moved_temporarily(conn, state) :: {{true, iodata()} | false, conn, state}
                                            | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [moved_temporarily: 2]

  @callback multiple_choices(conn, state) :: {boolean(), conn, state}
                                           | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [multiple_choices: 2]

  @callback options(conn, state) :: {:ok, conn, state}
                                  | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [options: 2]

  @callback previously_existed(conn, state) :: {boolean(), conn, state}
                                             | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [previously_existed: 2]

  @callback resource_exists(conn, state) :: {boolean(), conn, state}
                                          | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [resource_exists: 2]

  @callback service_available(conn, state) :: {boolean(), conn, state}
                                            | {:stop, conn, state}
            when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [service_available: 2]

  @callback uri_too_long(conn, state) :: {boolean(), conn, state}
                                       | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [uri_too_long: 2]

  @callback valid_content_headers(conn, state) :: {boolean(), conn, state}
                                                | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [valid_content_headers: 2]

  @callback valid_entity_length(conn, state) :: {boolean(), conn, state}
                                              | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [valid_entity_length: 2]

  @callback variances(conn, state) :: {[binary()], conn, state}
                                    | {:stop, conn, state}
          when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [variances: 2]

  def upgrade(conn, handler, _opts \\ []) do
    method = conn.method
    state = %PlugRest.State{method: method, handler: handler}
    service_available(conn, state)
  end

  defp service_available(conn, state) do
    expect(conn, state, :service_available, true, &known_methods/2, 503)
  end

  defp known_methods(conn, %{method: var_method} = state) do
    case call(conn, state, :known_methods) do
      :no_call when var_method === "HEAD" or var_method === "GET"
      or var_method === "POST" or var_method === "PUT"
      or var_method === "PATCH" or var_method === "DELETE"
      or var_method === "OPTIONS" ->
        next(conn, state, &uri_too_long/2)
      :no_call ->
        next(conn, state, 501)
      {:halt, conn2, handler_state} ->
        terminate(conn2, %{state | :handler_state => handler_state})
      {list, conn2, handler_state} ->
        state2 = %{state | :handler_state => handler_state}
        case Enum.member?(list, var_method) do
          true ->
            next(conn2, state2, &uri_too_long/2)
          false ->
            next(conn2, state2, 501)
        end
    end
  end

  defp uri_too_long(conn, state) do
    expect(conn, state, :uri_too_long, false, &allowed_methods/2, 414)
  end

  defp allowed_methods(conn, %{method: var_method} = state) do
    case call(conn, state, :allowed_methods) do
      :no_call when var_method === "HEAD" or var_method === "GET" ->
        next(conn, state, &malformed_request/2)
      :no_call when var_method === "OPTIONS" ->
        next(conn, %{state | allowed_methods: ["HEAD", "GET", "OPTIONS"]}, &malformed_request/2)
      :no_call ->
        method_not_allowed(conn, state, ["HEAD", "GET", "OPTIONS"])
      {:halt, conn2, handler_state} ->
        terminate(conn2, %{state | :handler_state => handler_state})
      {list, conn2, handler_state} ->
        state2 = %{state | :handler_state => handler_state}
        case Enum.member?(list, var_method) do
          true when var_method === "OPTIONS" ->
            next(conn2, %{state2 | allowed_methods: list}, &malformed_request/2)
          true ->
            next(conn2, state2, &malformed_request/2)
          false ->
            method_not_allowed(conn2, state2, list)
        end
    end
  end

  defp method_not_allowed(conn, state, []) do
    conn |> put_resp_header("allow", "") |> respond(state, 405)
  end

  defp method_not_allowed(conn, state, methods) do
    <<", ", allow::binary>> = for(m <- methods, into: <<>>, do: <<", ", m::binary>>)
    conn |> put_resp_header("allow", allow) |> respond(state, 405)
  end

  defp malformed_request(conn, state) do
    expect(conn, state, :malformed_request, false, &is_authorized/2, 400)
  end

  defp is_authorized(conn, state) do
    case call(conn, state, :is_authorized) do
      :no_call ->
        forbidden(conn, state)
      {:halt, conn2, handler_state} ->
        terminate(conn2, %{state | :handler_state => handler_state})
      {true, conn2, handler_state} ->
        forbidden(conn2, %{state | :handler_state => handler_state})
      {{false, auth_head}, conn2, handler_state} ->
        conn2
        |> put_resp_header("www-authenticate", auth_head)
        |> respond(%{state | :handler_state => handler_state}, 401)
    end
  end

  defp forbidden(conn, state) do
    expect(conn, state, :forbidden, false, &valid_content_headers/2, 403)
  end

  defp valid_content_headers(conn, state) do
    expect(conn, state, :valid_content_headers, true, &known_content_type/2, 501)
  end

  defp known_content_type(conn, state) do
    expect(conn, state, :known_content_type, true, &valid_entity_length/2, 415)
  end

  defp valid_entity_length(conn, state) do
    expect(conn, state, :valid_entity_length, true, &options/2, 413)
  end

  defp options(conn, %{allowed_methods: methods, method: "OPTIONS"} = state) do
    case call(conn, state, :options) do
      :no_call when methods === [] ->
        conn |> put_resp_header("allow", "") |> respond(state, 200)
      :no_call ->
        <<", ", allow::binary>> = for(m <- methods, into: <<>>, do: <<", ", m::binary>>)
        conn |> put_resp_header("allow", allow) |> respond(state, 200)
      {:halt, conn2, handler_state} ->
        terminate(conn2, %{state | :handler_state => handler_state})
      {:ok, conn2, handler_state} ->
        respond(conn2, %{state | :handler_state => handler_state}, 200)
    end
  end

  defp options(conn, state) do
    content_types_provided(conn, state)
  end

  defp content_types_provided(conn, state) do
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
        apply(handler, callback, [req, handler_state])
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
