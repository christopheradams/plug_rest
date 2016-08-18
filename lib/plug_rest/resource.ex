defmodule PlugRest.Resource do
  @moduledoc ~S"""
  Define callbacks and REST semantics for a Resource behaviour

  Based on Cowboy's cowboy_rest module. It operates on a Plug connection and a
  handler module which implements one or more of the optional callbacks.

  For example, the route:

      resource "/users/:username", MyApp.UserResource

  will invoke the `init/2` function of `MyApp.UserResource` if it exists
  and then continue executing to determine the state of the resource. By
  default the resource must implement a `to_html` content handler which
  returns a "text/html" representation of the resource.

      defmodule MyApp.UserResource do

        use PlugRest.Resource

        def init(conn, _state) do
          params = read_path_params(conn)
          username = params["username"]
          state = %{username: username}
          {:ok, conn, state}
        end

        def allowed_methods(conn, state) do
          {["GET"], conn, state}
        end

        def resource_exists(conn, %{username: username} = state)
          # Look up user
          state2 = %{state | name: "John Doe"}
          {true, conn, state2}
        end

        def content_types_provided(conn, state) do
          {[{"text/html", :to_html}], conn, state}
        end

        def to_html(conn, %{name: name} = state) do
          {"<p>Hello, #{name}</p>", conn, state}
        end
      end

  Each callback accepts a `%Plug.Conn{}` struct and the current state
  of the resource, and returns a three-element tuple of the form `{value,
  conn, state}`.

  The resource callbacks are named below, along with their default
  values. Some functions are skipped if they are undefined. Others have
  no default value.

      allowed_methods        : ["GET", "HEAD", "OPTIONS"]
      allow_missing_post     : true
      charsets_provided      : skip
      content_types_accepted : none
      content_types_provided : [{{"text", "html", %{}}, :to_html}]
      delete_completed       : true
      delete_resource        : false
      expires                : nil
      forbidden              : false
      generate_etag          : nil
      is_authorized          : true
      is_conflict            : false
      known_methods          : ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
      languages_provided     : skip
      last_modified          : nil
      malformed_request      : false
      moved_permanently      : false
      moved_temporarily      : false
      multiple_choices       : false
      options                : :ok
      previously_existed     : false
      resource_exists        : true
      service_available      : true
      uri_too_long           : false
      valid_content_headers  : true
      valid_entity_length    : true
      variances              : []

  You must also define the content handler callbacks that are specified
  through `content_types_accepted/2` and `content_types_provided/2`. It is
  conventional to name the functions after the content types that they
  handle, such as `from_html` and `to_html`.

  The handler function which provides a representation of the resource
  must return a three element tuple of the form `{body, conn, state}`,
  where `body` is one of:

  * `binary()`, which will be sent with `send_resp/3`
  * `{:chunked, Enum.t}, which will use `send_chunked/2`
  * `{:file, binary()}, which will use `send_file/3`
  """

  import PlugRest.Utils
  import PlugRest.Conn
  import Plug.Conn

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour PlugRest.Resource

      import Plug.Conn
      import PlugRest.Conn, only: [read_path_params: 1]

      def init(options) do
        options
      end

      def call(conn, options) do
        handler_state = Keyword.get(options, :state)
        PlugRest.Resource.upgrade(conn, __MODULE__, handler_state)
      end

      defoverridable [init: 1, call: 2]
    end
  end

  @type conn :: Plug.Conn.t
  @type opts :: Plug.opts
  @type state :: PlugRest.State.t

  @type etag :: PlugRest.State.etag
  @type handler :: PlugRest.State.handler
  @type media_type :: PlugRest.State.media_type
  @type content_handler :: PlugRest.State.content_handler
  @type content_type_p :: {binary() | media_type, handler}

  @type etags_list :: PlugRest.Conn.etags_list
  @type priority_type :: PlugRest.Conn.priority_type
  @type quality_type :: PlugRest.Conn.quality_type

  @type status_code :: 200..503

  @default_media_type {"text", "html", %{}}
  @default_content_handler {@default_media_type, :to_html}

  ## Plug callbacks

  @callback init(opts) :: opts
  @optional_callbacks [init: 1]

  ## Common handler callbacks

  @callback init(conn, state) :: {:ok, conn, state}
                               | {:stop, conn, state}
  @optional_callbacks [init: 2]

  ## REST handler callbacks

  @callback allowed_methods(conn, state) :: {[binary()], conn, state}
                                          | {:stop, conn, state}
  @optional_callbacks [allowed_methods: 2]

  @callback allow_missing_post(conn, state) :: {boolean(), conn, state}
                                             | {:stop, conn, state}
  @optional_callbacks [allow_missing_post: 2]

  @callback charsets_provided(conn, state) :: {[binary()], conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [charsets_provided: 2]

  @callback content_types_accepted(conn, state) :: {[media_type], conn, state}
                                                 | {:stop, conn, state}
  @optional_callbacks [content_types_accepted: 2]

  @callback content_types_provided(conn, state) :: {[content_type_p], conn, state}
                                                 | {:stop, conn, state}
  @optional_callbacks [content_types_provided: 2]

  @callback delete_completed(conn, state) :: {boolean(), conn, state}
                                           | {:stop, conn, state}
  @optional_callbacks [delete_completed: 2]

  @callback delete_resource(conn, state) :: {boolean(), conn, state}
                                          | {:stop, conn, state}
  @optional_callbacks [delete_resource: 2]

  @callback expires(conn, state) :: {:calendar.datetime() | binary() | nil, conn, state}
                                  | {:stop, conn, state}
  @optional_callbacks [expires: 2]

  @callback forbidden(conn, state) :: {boolean(), conn, state}
                                    | {:stop, conn, state}
  @optional_callbacks [forbidden: 2]

  @callback generate_etag(conn, state) :: {binary() | {:weak | :strong, binary()}, conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [generate_etag: 2]

  @callback is_authorized(conn, state) :: {true | {false, binary()}, conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [is_authorized: 2]

  @callback is_conflict(conn, state) :: {boolean(), conn, state}
                                      | {:stop, conn, state}
  @optional_callbacks [is_conflict: 2]

  @callback known_methods(conn, state) :: {[binary()], conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [known_methods: 2]

  @callback languages_provided(conn, state) :: {[binary()], conn, state}
                                             | {:stop, conn, state}
  @optional_callbacks [languages_provided: 2]

  @callback last_modified(conn, state) :: {:calendar.datetime(), conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [last_modified: 2]

  @callback malformed_request(conn, state) :: {boolean(), conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [malformed_request: 2]

  @callback moved_permanently(conn, state) :: {{true, binary()} | false, conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [moved_permanently: 2]

  @callback moved_temporarily(conn, state) :: {{true, binary()} | false, conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [moved_temporarily: 2]

  @callback multiple_choices(conn, state) :: {boolean(), conn, state}
                                           | {:stop, conn, state}
  @optional_callbacks [multiple_choices: 2]

  @callback options(conn, state) :: {:ok, conn, state}
                                  | {:stop, conn, state}
  @optional_callbacks [options: 2]

  @callback previously_existed(conn, state) :: {boolean(), conn, state}
                                             | {:stop, conn, state}
  @optional_callbacks [previously_existed: 2]

  @callback resource_exists(conn, state) :: {boolean(), conn, state}
                                          | {:stop, conn, state}
  @optional_callbacks [resource_exists: 2]

  @callback service_available(conn, state) :: {boolean(), conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [service_available: 2]

  @callback uri_too_long(conn, state) :: {boolean(), conn, state}
                                       | {:stop, conn, state}
  @optional_callbacks [uri_too_long: 2]

  @callback valid_content_headers(conn, state) :: {boolean(), conn, state}
                                                | {:stop, conn, state}
  @optional_callbacks [valid_content_headers: 2]

  @callback valid_entity_length(conn, state) :: {boolean(), conn, state}
                                              | {:stop, conn, state}
  @optional_callbacks [valid_entity_length: 2]

  @callback variances(conn, state) :: {[binary()], conn, state}
                                    | {:stop, conn, state}
  @optional_callbacks [variances: 2]


  @doc """
  Executes the REST state machine with a connection and resource

  Accepts a Plug.Conn struct, a PlugRest.Resource handler module, and an
  initial resource state, and executes the REST state machine.
  """
  @spec upgrade(conn, handler, any()) :: conn
  def upgrade(conn, handler, handler_state) do
    method = conn.method
    state = %PlugRest.State{method: method, handler: handler,
                            handler_state: handler_state}

    case Code.ensure_loaded?(handler) do
      true ->
        expect(conn, state, :init, :ok, &service_available/2, 500)
      false ->
        respond(conn, state, 500)
    end
  end

  @spec service_available(conn, state) :: conn
  defp service_available(conn, state) do
    expect(conn, state, :service_available, true, &known_methods/2, 503)
  end

  @spec known_methods(conn, state) :: conn
  defp known_methods(conn, %{method: var_method} = state) do
    case call(conn, state, :known_methods) do
      :no_call when var_method === "HEAD" or var_method === "GET"
      or var_method === "POST" or var_method === "PUT"
      or var_method === "PATCH" or var_method === "DELETE"
      or var_method === "OPTIONS" ->
        next(conn, state, &uri_too_long/2)
      :no_call ->
        next(conn, state, 501)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {list, conn2, handler_state} ->
        state2 = %{state | handler_state: handler_state}
        case Enum.member?(list, var_method) do
          true ->
            next(conn2, state2, &uri_too_long/2)
          false ->
            next(conn2, state2, 501)
        end
    end
  end

  @spec uri_too_long(conn, state) :: conn
  defp uri_too_long(conn, state) do
    expect(conn, state, :uri_too_long, false, &allowed_methods/2, 414)
  end

  @spec allowed_methods(conn, state) :: conn
  defp allowed_methods(conn, %{method: var_method} = state) do
    case call(conn, state, :allowed_methods) do
      :no_call when var_method === "HEAD" or var_method === "GET" ->
        next(conn, state, &malformed_request/2)
      :no_call when var_method === "OPTIONS" ->
        next(conn, %{state | allowed_methods: ["HEAD", "GET", "OPTIONS"]}, &malformed_request/2)
      :no_call ->
        method_not_allowed(conn, state, ["HEAD", "GET", "OPTIONS"])
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {list, conn2, handler_state} ->
        state2 = %{state | handler_state: handler_state}
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

  @spec method_not_allowed(conn, state, [binary()]) :: conn
  defp method_not_allowed(conn, state, []) do
    conn |> put_resp_header("allow", "") |> respond(state, 405)
  end

  defp method_not_allowed(conn, state, methods) do
    <<", ", allow::binary>> = for(m <- methods, into: <<>>, do: <<", ", m::binary>>)
    conn |> put_resp_header("allow", allow) |> respond(state, 405)
  end

  @spec malformed_request(conn, state) :: conn
  defp malformed_request(conn, state) do
    expect(conn, state, :malformed_request, false, &is_authorized/2, 400)
  end

  @spec is_authorized(conn, state) :: conn
  defp is_authorized(conn, state) do
    case call(conn, state, :is_authorized) do
      :no_call ->
        forbidden(conn, state)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {true, conn2, handler_state} ->
        forbidden(conn2, %{state | handler_state: handler_state})
      {{false, auth_head}, conn2, handler_state} ->
        conn2
        |> put_resp_header("www-authenticate", auth_head)
        |> respond(%{state | handler_state: handler_state}, 401)
    end
  end

  @spec forbidden(conn, state) :: conn
  defp forbidden(conn, state) do
    expect(conn, state, :forbidden, false, &valid_content_headers/2, 403)
  end

  @spec valid_content_headers(conn, state) :: conn
  defp valid_content_headers(conn, state) do
    expect(conn, state, :valid_content_headers, true, &valid_entity_length/2, 501)
  end

  @spec valid_entity_length(conn, state) :: conn
  defp valid_entity_length(conn, state) do
    expect(conn, state, :valid_entity_length, true, &options/2, 413)
  end

  @spec options(conn, state) :: conn
  defp options(conn, %{allowed_methods: methods, method: "OPTIONS"} = state) do
    case call(conn, state, :options) do
      :no_call when methods === [] ->
        conn |> put_resp_header("allow", "") |> respond(state, 200)
      :no_call ->
        <<", ", allow::binary>> = for(m <- methods, into: <<>>, do: <<", ", m::binary>>)
        conn |> put_resp_header("allow", allow) |> respond(state, 200)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {:ok, conn2, handler_state} ->
        respond(conn2, %{state | handler_state: handler_state}, 200)
    end
  end

  defp options(conn, state) do
    content_types_provided(conn, state)
  end

  @spec content_types_provided(conn, state) :: conn
  defp content_types_provided(conn, state) do
    case call(conn, state, :content_types_provided) do
      :no_call ->
        state2 = %{state | content_types_p: [@default_content_handler]}
        try do
          case parse_media_range_header(conn, "accept") do
            [] ->
              conn
              |> put_resp_content_type(print_media_type(@default_media_type))
              |> languages_provided(%{state2 | content_type_a: @default_content_handler})
            accept ->
              choose_media_type(conn, state2, prioritize_accept(accept))
          end
        catch
          _, _ ->
            respond(conn, state2, 400)
        end
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {[], conn2, handler_state} ->
        not_acceptable(conn2, %{state | handler_state: handler_state})
      {c_tp, conn2, handler_state} ->
        c_tp2 = for(p <- c_tp, into: [], do: normalize_content_types(p))
        state2 = %{state | handler_state: handler_state, content_types_p: c_tp2}
        try do
          case parse_media_range_header(conn2, "accept") do
            [] ->
              {p_mt, _fun} = head_ctp = hd(c_tp2)
              conn2
              |> put_resp_content_type(print_media_type(p_mt))
              |> languages_provided(%{state2 | content_type_a: head_ctp})
            accept ->
              choose_media_type(conn2, state2, prioritize_accept(accept))
          end
        catch
          _, _ ->
            respond(conn2, state2, 400)
        end
    end
  end

  @spec normalize_content_types(content_type_p) :: media_type
  defp normalize_content_types({content_type, callback}) when is_binary(content_type) do
    {:ok, type, subtype, params} = Plug.Conn.Utils.media_type(content_type)
    {{type, subtype, params}, callback}
  end

  defp normalize_content_types(normalized) do
    normalized
  end


  @spec prioritize_accept([priority_type]) :: [priority_type]
  defp prioritize_accept(accept) do
    accept
    |> Enum.sort(fn
      {media_type_a, quality, _accept_params_a},
      {media_type_b, quality, _accept_params_b} ->
        prioritize_mediatype(media_type_a, media_type_b)
      {_media_type_a, quality_a, _accept_params_a},
      {_media_type_b, quality_b, _accept_params_b} ->
        quality_a > quality_b
    end)
  end


  @spec prioritize_mediatype(media_type, media_type) :: boolean()
  defp prioritize_mediatype({type_a, sub_type_a, params_a}, {type_b, sub_type_b, params_b}) do
    case type_b do
      ^type_a ->
        case sub_type_b do
          ^sub_type_a ->
            length(params_a) > length(params_b)
          "*" ->
            true
          _any ->
            false
        end
      "*" ->
        true
      _any ->
        false
    end
  end


  @spec choose_media_type(conn, state, [priority_type]) :: conn
  defp choose_media_type(conn, state, []) do
    not_acceptable(conn, state)
  end

  defp choose_media_type(conn, %{content_types_p: c_tp} = state, [media_type | tail]) do
    match_media_type(conn, state, tail, c_tp, media_type)
  end


  @spec match_media_type(conn, state, [priority_type], [content_handler], priority_type) :: conn
  defp match_media_type(conn, state, accept, [], _media_type) do
    choose_media_type(conn, state, accept)
  end

  defp match_media_type(conn, state, accept, c_tp,
  media_type = {{"*", "*", _params_a}, _q_a, _a_pa}) do
    match_media_type_params(conn, state, accept, c_tp, media_type)
  end

  defp match_media_type(conn, state, accept, c_tp = [{{type, sub_type_p, _p_p}, _fun} | _tail],
  media_type = {{type, sub_type_a, _p_a}, _q_a, _a_pa})
  when sub_type_p === sub_type_a or sub_type_a === "*" do
    match_media_type_params(conn, state, accept, c_tp, media_type)
  end

  defp match_media_type(conn, state, accept, [_any | tail], media_type) do
    match_media_type(conn, state, accept, tail, media_type)
  end


  @spec match_media_type_params(conn, state, [priority_type], [content_handler], priority_type) :: conn
  defp match_media_type_params(conn, state, _accept,
  [provided = {{t_p, s_tp, :*}, _fun} | _tail],
  {{_t_a, _s_ta, params_a}, _q_a, _a_pa}) do
    p_mt = {t_p, s_tp, params_a}
    conn
    |> put_media_type(p_mt)
    |> put_resp_content_type(print_media_type(p_mt))
    |> languages_provided(%{state | content_type_a: provided})
  end

  defp match_media_type_params(conn, state, accept,
  [provided = {p_mt = {_t_p, _s_tp, params_p}, _fun} | tail],
  media_type = {{_t_a, _s_ta, params_a}, _q_a, _a_pa}) do
    case params_p === params_a do
      true ->
        conn
        |> put_media_type(p_mt)
        |> put_resp_content_type(print_media_type(p_mt))
        |> languages_provided(%{state | content_type_a: provided})
      false ->
        match_media_type(conn, state, accept, tail, media_type)
    end
  end

  @spec languages_provided(conn, state) :: conn
  defp languages_provided(conn, state) do
    case call(conn, state, :languages_provided) do
      :no_call ->
        charsets_provided(conn, state)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {[], conn2, handler_state} ->
        not_acceptable(conn2, %{state | handler_state: handler_state})
      {l_p, conn2, handler_state} ->
        state2 = %{state | handler_state: handler_state, languages_p: l_p}
        case parse_quality_header(conn2, "accept-language") do
          [] ->
            set_language(conn2, %{state2 | language_a: hd(l_p)})
          accept_language ->
            accept_language2 = prioritize_languages(accept_language)
            choose_language(conn2, state2, accept_language2)
        end
    end
  end


  @spec prioritize_languages([quality_type]) :: [quality_type]
  defp prioritize_languages(accept_languages) do
    accept_languages
    |> Enum.sort(fn {_tag_a, quality_a}, {_tag_b, quality_b} -> quality_a > quality_b end)
  end


  @spec choose_language(conn, state, [quality_type]) :: conn
  defp choose_language(conn, state, []) do
    not_acceptable(conn, state)
  end

  defp choose_language(conn, %{languages_p: l_p} = state, [language | tail]) do
    match_language(conn, state, tail, l_p, language)
  end


  @spec match_language(conn, state, [quality_type], [binary()], quality_type) :: conn
  defp match_language(conn, state, accept, [], _language) do
    choose_language(conn, state, accept)
  end

  defp match_language(conn, state, _accept, [provided | _tail], {"*", _quality}) do
    set_language(conn, %{state | language_a: provided})
  end


  defp match_language(conn, state, _accept, [provided | _tail], {provided, _quality}) do
    set_language(conn, %{state | language_a: provided})
  end

  defp match_language(conn, state, accept, [provided | tail], language = {tag, _quality}) do
    var_length = byte_size(tag)
    case provided do
      <<^tag::size(var_length)-binary, ?-, _any::bits>> ->
        set_language(conn, %{state | language_a: provided})
      _any ->
        match_language(conn, state, accept, tail, language)
    end
  end


  @spec set_language(conn, state) :: conn
  defp set_language(conn, %{language_a: language} = state) do
    conn
    |> put_resp_header("content-language", language)
    |> charsets_provided(state)
  end


  @spec charsets_provided(conn, state) :: conn
  defp charsets_provided(conn, state) do
    case call(conn, state, :charsets_provided) do
      :no_call ->
        set_content_type(conn, state)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {[], conn2, handler_state} ->
        not_acceptable(conn2, %{state | handler_state: handler_state})
      {c_p, conn2, handler_state} ->
        state2 = %{state | handler_state: handler_state, charsets_p: c_p}
        case parse_quality_header(conn2, "accept-charset") do
          [] ->
            set_content_type(conn2, %{state2 | charset_a: hd(c_p)})
          accept_charset ->
            accept_charset2 = prioritize_charsets(accept_charset)
            choose_charset(conn2, state2, accept_charset2)
        end
    end
  end


  @spec prioritize_charsets([quality_type]) :: [quality_type]
  defp prioritize_charsets(accept_charsets) do
    accept_charsets2 = :lists.sort(fn {_charset_a, quality_a}, {_charset_b, quality_b} ->
      quality_a > quality_b end, accept_charsets)
    case :lists.keymember("*", 1, accept_charsets2) do
      true ->
        accept_charsets2
      false ->
        case :lists.keymember("iso-8859-1", 1, accept_charsets2) do
          true ->
            accept_charsets2
          false ->
            [{"iso-8859-1", 1000} | accept_charsets2]
        end
    end
  end


  @spec choose_charset(conn, state, [quality_type]) :: conn
  defp choose_charset(conn, state, []) do
    not_acceptable(conn, state)
  end

  defp choose_charset(conn, %{charsets_p: c_p} = state, [charset | tail]) do
    match_charset(conn, state, tail, c_p, charset)
  end


  @spec match_charset(conn, state, [quality_type], [binary()], quality_type) :: conn
  defp match_charset(conn, state, accept, [], _charset) do
    choose_charset(conn, state, accept)
  end

  defp match_charset(conn, state, _accept, [provided | _], {provided, _}) do
    set_content_type(conn, %{state | charset_a: provided})
  end

  defp match_charset(conn, state, accept, [_ | tail], charset) do
    match_charset(conn, state, accept, tail, charset)
  end


  @spec set_content_type(conn, state) :: conn
  defp set_content_type(conn, %{content_type_a: {{type, sub_type, params}, _fun},
  charset_a: charset} = state) do
    params_bin = set_content_type_build_params(params)
    content_type = print_media_type({type, sub_type, params_bin})
    conn2 = case charset do
      nil ->
        put_resp_content_type(conn, content_type)
      ^charset ->
        put_resp_content_type(conn, content_type, charset)
    end
    conn2
    |> encodings_provided(state)
  end


  @spec set_content_type_build_params(:* | map()) :: binary()
  defp set_content_type_build_params(:*) do
    ""
  end

  defp set_content_type_build_params(params) when is_map(params) do
    Enum.map(params, fn ({k, v}) -> "#{k}=#{v}" end) |> Enum.join(";")
  end


  @spec encodings_provided(conn, state) :: conn
  defp encodings_provided(conn, state) do
    variances(conn, state)
  end


  @spec not_acceptable(conn, state) :: conn
  defp not_acceptable(conn, state) do
    respond(conn, state, 406)
  end


  @spec variances(conn, state) :: conn
  defp variances(conn, %{content_types_p: c_tp, languages_p: l_p, charsets_p: c_p} = state) do
    var_variances = case c_tp do
      [] ->
        []
      [_] ->
        []
      [_ | _] ->
        ["accept"]
    end
    variances2 = case l_p do
      [] ->
        var_variances
      [_] ->
        var_variances
      [_ | _] ->
        ["accept-language" | var_variances]
    end
    variances3 = case c_p do
      [] ->
        variances2
      [_] ->
        variances2
      [_ | _] ->
        ["accept-charset" | variances2]
    end
    try do
      case variances(conn, state, variances3) do
        {variances4, conn2, state2} ->
          case for(v <- variances4, into: [], do: [", ", v]) do
                [] ->
                  resource_exists(conn2, state2)
                [[", ", h] | variances5] ->
                  conn3 = put_resp_header(conn2, "vary", List.to_string([h | variances5]))
                  resource_exists(conn3, state2)
            end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :variances)
    end
  end


  defp variances(conn, state, var_variances) do
    case unsafe_call(conn, state, :variances) do
      :no_call ->
        {var_variances, conn, state}
      {handler_variances, conn2, handler_state} ->
        {var_variances ++ handler_variances, conn2, %{state | handler_state: handler_state}}
    end
  end


  @spec resource_exists(conn, state) :: conn
  defp resource_exists(conn, state) do
    expect(conn, state, :resource_exists, true, &if_match_exists/2, &if_match_must_not_exist/2)
  end


  @spec if_match_exists(conn, state) :: conn
  defp if_match_exists(conn, state) do
    state2 = %{state | exists: true}
    case parse_entity_tag_header(conn, "if-match") do
      [] ->
        if_unmodified_since_exists(conn, state2)
      [%{}] ->
        if_unmodified_since_exists(conn, state2)
      etags_list ->
        if_match(conn, state2, etags_list)
    end
  end


  @spec if_match(conn, state, etags_list) :: conn
  defp if_match(conn, state, etags_list) do
    try do
      case generate_etag(conn, state) do
        {{:weak, _}, conn2, state2} ->
          precondition_failed(conn2, state2)
        {etag, conn2, state2} ->
          case :lists.member(etag, etags_list) do
            true ->
              if_none_match_exists(conn2, state2)
            false ->
              precondition_failed(conn2, state2)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    end
  end


  @spec if_match_must_not_exist(conn, state) :: conn
  defp if_match_must_not_exist(conn, state) do
    case get_req_header(conn, "if-match") do
      [] ->
        is_put_to_missing_resource(conn, state)
      _ ->
        precondition_failed(conn, state)
    end
  end


  @spec if_unmodified_since_exists(conn, state) :: conn
  defp if_unmodified_since_exists(conn, state) do
    try do
      case parse_date_header(conn, "if-unmodified-since") do
        [] ->
          if_none_match_exists(conn, state)
        if_unmodified_since ->
          if_unmodified_since(conn, state, if_unmodified_since)
      end
    catch
      _, _ ->
        if_none_match_exists(conn, state)
    end
  end


  @spec if_unmodified_since(conn, state, :calendar.time) :: conn
  defp if_unmodified_since(conn, state, if_unmodified_since) do
    try do
      case last_modified(conn, state) do
        {last_modified, conn2, state2} ->
          case last_modified > if_unmodified_since do
            true ->
              precondition_failed(conn2, state2)
            false ->
              if_none_match_exists(conn2, state2)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :last_modified)
    end
  end


  @spec if_none_match_exists(conn, state) :: conn
  defp if_none_match_exists(conn, state) do
    case parse_entity_tag_header(conn, "if-none-match") do
      [] ->
        if_modified_since_exists(conn, state)
      [%{}] ->
        precondition_is_head_get(conn, state)
      etags_list ->
        if_none_match(conn, state, etags_list)
    end
  end


  @spec if_none_match(conn, state, etags_list) :: conn
  defp if_none_match(conn, state, etags_list) do
    try do
      case generate_etag(conn, state) do
        {etag, conn2, state2} ->
          case etag do
            nil ->
              precondition_failed(conn2, state2)
            ^etag ->
              case is_weak_match(etag, etags_list) do
                true ->
                  precondition_is_head_get(conn2, state2)
                false ->
                  method(conn2, state2)
              end
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    end
  end


  @spec is_weak_match(etag, etags_list) :: boolean()
  defp is_weak_match(_, []) do
    false
  end

  defp is_weak_match({_, tag}, [{_, tag} | _]) do
    true
  end

  defp is_weak_match(etag, [_ | tail]) do
    is_weak_match(etag, tail)
  end


  @spec precondition_is_head_get(conn, state) :: conn
  defp precondition_is_head_get(conn, %{method: var_method} = state)
  when var_method === "HEAD" or var_method === "GET" do
    not_modified(conn, state)
  end

  defp precondition_is_head_get(conn, state) do
    precondition_failed(conn, state)
  end


  @spec if_modified_since_exists(conn, state) :: conn
  defp if_modified_since_exists(conn, state) do
    try do
      case parse_date_header(conn, "if-modified-since") do
        [] ->
          method(conn, state)
        if_modified_since ->
          if_modified_since_now(conn, state, if_modified_since)
      end
    catch
      _, _ ->
        method(conn, state)
    end
  end


  @spec if_modified_since_now(conn, state, :calendar.time) :: conn
  defp if_modified_since_now(conn, state, if_modified_since) do
    universaltime = Application.get_env(:plug_rest, :current_time_fun)
    case if_modified_since > universaltime.() do
      true ->
        method(conn, state)
      false ->
        if_modified_since(conn, state, if_modified_since)
    end
  end


  defp if_modified_since(conn, state, if_modified_since) do
    try do
      case last_modified(conn, state) do
        {nil, conn2, state2} ->
          method(conn2, state2)
        {last_modified, conn2, state2} ->
          case last_modified > if_modified_since do
            true ->
              method(conn2, state2)
            false ->
              not_modified(conn2, state2)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :last_modified)
    end
  end


  @spec not_modified(conn, state) :: conn
  defp not_modified(conn, state) do
    conn2 = delete_resp_header(conn, "content-type")
    try do
      case set_resp_etag(conn2, state) do
        {conn3, state2} ->
          try do
            case set_resp_expires(conn3, state2) do
            {req4, state3} ->
              respond(req4, state3, 304)
            end
          catch
            class, reason ->
              error_terminate(conn, state2, class, reason, :expires)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    end
  end


  @spec precondition_failed(conn, state) :: conn
  defp precondition_failed(conn, state) do
    respond(conn, state, 412)
  end


  @spec is_put_to_missing_resource(conn, state) :: conn
  defp is_put_to_missing_resource(conn, %{method: "PUT"} = state) do
    moved_permanently(conn, state, &is_conflict/2)
  end

  defp is_put_to_missing_resource(conn, state) do
    previously_existed(conn, state)
  end


  @spec moved_permanently(conn, state, (conn, state -> conn)) :: conn
  defp moved_permanently(conn, state, on_false) do
    case call(conn, state, :moved_permanently) do
      {{true, location}, conn2, handler_state} ->
        conn3 = put_resp_header(conn2, "location", location)
        respond(conn3, %{state | handler_state: handler_state}, 301)
      {false, conn2, handler_state} ->
        on_false.(conn2, %{state | handler_state: handler_state})
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      :no_call ->
        on_false.(conn, state)
    end
  end


  @spec previously_existed(conn, state) :: conn
  defp previously_existed(conn, state) do
    expect(conn, state, :previously_existed, false,
      fn r, s -> is_post_to_missing_resource(r, s, 404) end,
      fn r, s -> moved_permanently(r, s, &moved_temporarily/2) end)
  end


  @spec moved_temporarily(conn, state) :: conn
  defp moved_temporarily(conn, state) do
    case call(conn, state, :moved_temporarily) do
      {{true, location}, conn2, handler_state} ->
        conn3 = put_resp_header(conn2, "location", location)
        respond(conn3, %{state | handler_state: handler_state}, 307)
      {false, conn2, handler_state} ->
        is_post_to_missing_resource(conn2, %{state | handler_state: handler_state}, 410)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      :no_call ->
        is_post_to_missing_resource(conn, state, 410)
    end
  end


  @spec is_post_to_missing_resource(conn, state, status_code) :: conn
  defp is_post_to_missing_resource(conn, %{method: "POST"} = state, on_false) do
    allow_missing_post(conn, state, on_false)
  end

  defp is_post_to_missing_resource(conn, state, on_false) do
    respond(conn, state, on_false)
  end


  @spec allow_missing_post(conn, state, status_code) :: conn
  defp allow_missing_post(conn, state, on_false) do
    expect(conn, state, :allow_missing_post, true, &accept_resource/2, on_false)
  end


  @spec method(conn, state) :: conn
  defp method(conn, %{method: "DELETE"} = state) do
    delete_resource(conn, state)
  end

  defp method(conn, %{method: "PUT"} = state) do
    is_conflict(conn, state)
  end

  defp method(conn, %{method: var_method} = state)
  when var_method === "POST" or var_method === "PATCH" do
    accept_resource(conn, state)
  end

  defp method(conn, %{method: var_method} = state)
  when var_method === "GET" or var_method === "HEAD" do
    set_resp_body_etag(conn, state)
  end

  defp method(conn, state) do
    multiple_choices(conn, state)
  end


  @spec delete_resource(conn, state) :: conn
  defp delete_resource(conn, state) do
    expect(conn, state, :delete_resource, false, 500, &delete_completed/2)
  end


  @spec delete_completed(conn, state) :: conn
  defp delete_completed(conn, state) do
    expect(conn, state, :delete_completed, true, &has_resp_body/2, 202)
  end


  @spec is_conflict(conn, state) :: conn
  defp is_conflict(conn, state) do
    expect(conn, state, :is_conflict, false, &accept_resource/2, 409)
  end


  @spec accept_resource(conn, state) :: conn
  defp accept_resource(conn, state) do
    case call(conn, state, :content_types_accepted) do
      :no_call ->
        respond(conn, state, 415)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {c_ta, conn2, handler_state} ->
        c_ta2 = for(p <- c_ta, into: [], do: normalize_content_types(p))
        state2 = %{state | handler_state: handler_state}
        try do
          case parse_media_type_header(conn2, "content-type") do
            content_type ->
              choose_content_type(conn2, state2, content_type, c_ta2)
          end
        catch
          _, _ ->
            respond(conn2, state2, 415)
        end
    end
  end


  @spec choose_content_type(conn, state, media_type, [media_type]) :: conn
  defp choose_content_type(conn, state, _content_type, []) do
    respond(conn, state, 415)
  end

  defp choose_content_type(conn, state, content_type, [{accepted, fun} | _tail])
  when accepted === :* or accepted === content_type do
    process_content_type(conn, state, fun)
  end

  defp choose_content_type(conn, state, {type, sub_type, param},
  [{{type, sub_type, accepted_param}, fun} | _tail])
  when accepted_param === :* or accepted_param === param do
    process_content_type(conn, state, fun)
  end

  defp choose_content_type(conn, state, content_type, [_any | tail]) do
    choose_content_type(conn, state, content_type, tail)
  end


  @spec process_content_type(conn, state, atom()) :: conn
  defp process_content_type(conn, %{method: var_method, exists: exists} = state, fun) do
    try do
      case call(conn, state, fun) do
        {:stop, conn2, handler_state2} ->
          terminate(conn2, %{state | handler_state: handler_state2})
        {true, conn2, handler_state2} when exists ->
          state2 = %{state | handler_state: handler_state2}
          next(conn2, state2, &has_resp_body/2)
        {true, conn2, handler_state2} ->
          state2 = %{state | handler_state: handler_state2}
          next(conn2, state2, &maybe_created/2)
        {false, conn2, handler_state2} ->
          state2 = %{state | handler_state: handler_state2}
          respond(conn2, state2, 400)
        {{true, res_url}, conn2, handler_state2} when var_method === "POST" ->
          state2 = %{state | handler_state: handler_state2}
          conn3 = put_resp_header(conn2, "location", res_url)
          if exists do
            respond(conn3, state2, 303)
          else
            respond(conn3, state2, 201)
          end
      end
    catch
      class, reason = {:case_clause, :no_call} ->
        error_terminate(conn, state, class, reason, fun)
    end
  end


  @spec maybe_created(conn, state) :: conn
  defp maybe_created(conn, %{method: "PUT"} = state) do
    respond(conn, state, 201)
  end

  defp maybe_created(conn, state) do
    case get_resp_header(conn, "location") do
      [] ->
        has_resp_body(conn, state)
      _ ->
        respond(conn, state, 201)
    end
  end


  @spec has_resp_body(conn, state) :: conn
  defp has_resp_body(conn, state) do
    case conn.resp_body do
      nil ->
        respond(conn, state, 204)
      _ ->
        multiple_choices(conn, state)
    end
  end


  @spec set_resp_body_etag(conn, state) :: conn
  defp set_resp_body_etag(conn, state) do
    try do
      case set_resp_etag(conn, state) do
        {conn2, state2} ->
          set_resp_body_last_modified(conn2, state2)
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    end
  end


  @spec set_resp_body_last_modified(conn, state) :: conn
  defp set_resp_body_last_modified(conn, state) do
    try do
      case last_modified(conn, state) do
        {last_modified, conn2, state2} ->
          case last_modified do
            ^last_modified when is_nil(last_modified) ->
              set_resp_body_expires(conn2, state2)
            ^last_modified ->
              last_modified_bin = :cowboy_clock.rfc1123(last_modified)
              conn3 = put_resp_header(conn2, "last-modified", last_modified_bin)
              set_resp_body_expires(conn3, state2)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :last_modified)
    end
  end


  @spec set_resp_body_expires(conn, state) :: conn
  defp set_resp_body_expires(conn, state) do
    try do
      case set_resp_expires(conn, state) do
        {conn2, state2} ->
          set_resp_body(conn2, state2)
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :expires)
    end
  end


  @spec set_resp_body(conn, state) :: conn
  defp set_resp_body(conn, %{content_type_a: {_, callback}} = state) do
    try do
      case call(conn, state, callback) do
        {:stop, conn2, handler_state2} ->
          terminate(conn2, %{state | handler_state: handler_state2})
        {body, conn2, handler_state2} ->
          state2 = %{state | handler_state: handler_state2, resp_body: body}
          multiple_choices(conn2, state2)
      end
    catch
      class, reason = {:case_clause, :no_call} ->
        error_terminate(conn, state, class, reason, callback)
    end
  end


  @spec multiple_choices(conn, state) :: conn
  defp multiple_choices(conn, state) do
    expect(conn, state, :multiple_choices, false, 200, 300)
  end


  @spec set_resp_etag(conn, state) :: {conn, state}
  defp set_resp_etag(conn, state) do
    {etag, conn2, state2} = generate_etag(conn, state)
    case etag do
      nil ->
        {conn2, state2}
      ^etag ->
        conn3 = put_resp_header(conn2, "etag", List.to_string(encode_etag(etag)))
        {conn3, state2}
    end
  end


  @spec encode_etag({:strong | :weak, binary()}) :: [binary()]
  defp encode_etag({:strong, etag}) do
    [?", etag, ?"]
  end

  defp encode_etag({:weak, etag}) do
    ['W/"', etag, ?"]
  end


  @spec set_resp_expires(conn, state) :: {conn, state}
  defp set_resp_expires(conn, state) do
    {var_expires, conn2, state2} = expires(conn, state)
    case var_expires do
      ^var_expires when is_nil(var_expires) ->
        {conn2, state2}
      ^var_expires when is_binary(var_expires) ->
        conn3 = put_resp_header(conn2, "expires", var_expires)
        {conn3, state2}
      ^var_expires ->
        expires_bin = :cowboy_clock.rfc1123(var_expires)
        conn3 = put_resp_header(conn2, "expires", expires_bin)
        {conn3, state2}
    end
  end


  @spec generate_etag(conn, state) :: {nil | {:weak | :strong, binary()}, conn, state}
  defp generate_etag(conn, %{etag: :no_call} = state) do
    {nil, conn, state}
  end

  defp generate_etag(conn, %{etag: nil} = state) do
    case unsafe_call(conn, state, :generate_etag) do
      :no_call ->
        {nil, conn, %{state | etag: :no_call}}
      {etag, conn2, handler_state} when is_binary(etag) ->
        {etag2} = List.to_tuple(:cowboy_http.entity_tag_match(etag))
        {etag2, conn2, %{state | handler_state: handler_state, etag: etag2}}
      {etag, conn2, handler_state} ->
        {etag, conn2, %{state | handler_state: handler_state, etag: etag}}
    end
  end

  defp generate_etag(conn, %{etag: etag} = state) do
    {etag, conn, state}
  end


  @spec last_modified(conn, state) :: {nil | :calendar.datetime(), conn, state}
  defp last_modified(conn, %{last_modified: :no_call} = state) do
    {nil, conn, state}
  end

  defp last_modified(conn, %{last_modified: nil} = state) do
    case unsafe_call(conn, state, :last_modified) do
      :no_call ->
        {nil, conn, %{state | last_modified: :no_call}}
      {last_modified, conn2, handler_state} ->
        {last_modified, conn2,
         %{state | handler_state: handler_state, last_modified: last_modified}}
    end
  end

  defp last_modified(conn, %{last_modified: last_modified} = state) do
    {last_modified, conn, state}
  end


  @spec expires(conn, state) :: {nil | :calendar.datetime() | binary, conn, state}
  defp expires(conn, %{expires: :no_call} = state) do
    {nil, conn, state}
  end

  defp expires(conn, %{expires: nil} = state) do
    case unsafe_call(conn, state, :expires) do
      :no_call ->
        {nil, conn, %{state | expires: :no_call}}
      {var_expires, conn2, handler_state} ->
        {var_expires, conn2, %{state | handler_state: handler_state, expires: var_expires}}
    end
  end

  defp expires(conn, %{expires: var_expires} = state) do
    {var_expires, conn, state}
  end

  ## REST primitives.

  defp expect(conn, state, callback, expected, on_true, on_false) do
    case call(conn, state, callback) do
      :no_call ->
        next(conn, state, on_true)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {^expected, conn2, handler_state} ->
        next(conn2, %{state | handler_state: handler_state}, on_true)
      {_unexpected, conn2, handler_state} ->
        next(conn2, %{state | handler_state: handler_state}, on_false)
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

  defp unsafe_call(conn, %{handler: handler, handler_state: handler_state}, callback) do
    case function_exported?(handler, callback, 2) do
      true ->
        apply(handler, callback, [conn, handler_state])
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

  defp terminate(%{resp_body: resp_body} = conn, state) when is_nil(resp_body) == false do
    state2 = %{state | resp_body: resp_body}
    conn2 = %{conn | resp_body: nil}
    terminate(conn2, state2)
  end

  defp terminate(conn, %{resp_body: nil} = state) do
    state2 = %{state | resp_body: ""}
    terminate(conn, state2)
  end

  defp terminate(conn, %{resp_body: {:chunked, body}} = _state) do
    conn2 = conn |> send_chunked(conn.status)
    Enum.into(body, conn2)
  end

  defp terminate(conn, %{resp_body: {:file, filename}} = _state) do
    send_file(conn, conn.status, filename)
  end

  defp terminate(conn, state) do
    conn |> send_resp(conn.status, state.resp_body)
  end

  defp error_terminate(conn, _state, _class, _reason, _callback) do
    conn |> send_resp(500, "")
  end
end
