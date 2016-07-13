defmodule PlugRest.Resource do
  import PlugRest.Utils
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

  defp forbidden(conn, state) do
    expect(conn, state, :forbidden, false, &valid_content_headers/2, 403)
  end

  defp valid_content_headers(conn, state) do
    expect(conn, state, :valid_content_headers, true, &valid_entity_length/2, 501)
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
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {:ok, conn2, handler_state} ->
        respond(conn2, %{state | handler_state: handler_state}, 200)
    end
  end

  defp options(conn, state) do
    content_types_provided(conn, state)
  end

  defp content_types_provided(conn, state) do
    case call(conn, state, :content_types_provided) do
      :no_call ->
        state2 = %{state | content_types_p: [{{"text", "html", %{}}, :to_html}]}
        try do
          case get_req_header(conn, "accept") do
            [] ->
              conn
              |> put_resp_content_type(print_media_type({"text", "html", %{}}))
              |> languages_provided(%{state2 | content_type_a: {{"text", "html", %{}}, :to_html}})
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
      {cTP, conn2, handler_state} ->
        cTP2 = for(p <- cTP, into: [], do: normalize_content_types(p))
        state2 = %{state | handler_state: handler_state, content_types_p: cTP2}
        try do
          case get_req_header(conn2, "accept") do
            [] ->
              {pMT, _fun} = headCTP = hd(cTP2)
              conn2
              |> put_resp_content_type(print_media_type(pMT))
              |> languages_provided(%{state2 | content_type_a: headCTP})
            accept ->
              choose_media_type(conn2, state2, prioritize_accept(accept))
          end
        catch
          _, _ ->
            respond(conn2, state2, 400)
        end
    end
  end


  defp normalize_content_types({content_type, callback}) when is_binary(content_type) do
    {:ok, type, subtype, params} = Plug.Conn.Utils.media_type(content_type)
    {{type, subtype, params}, callback}
  end

  defp normalize_content_types(normalized) do
    normalized
  end


  defp prioritize_accept(accept) do
    accept
    |> parse_accept_header
    |> reformat_media_types_for_cowboy_rest
    |> Enum.sort(fn
      {mediaTypeA, quality, _acceptParamsA}, {mediaTypeB, quality, _acceptParamsB} ->
        prioritize_mediatype(mediaTypeA, mediaTypeB)
      {_mediaTypeA, qualityA, _acceptParamsA}, {_mediaTypeB, qualityB, _acceptParamsB} ->
        qualityA > qualityB
    end)
  end


  defp prioritize_mediatype({typeA, subTypeA, paramsA}, {typeB, subTypeB, paramsB}) do
    case typeB do
      ^typeA ->
        case subTypeB do
          ^subTypeA ->
            length(paramsA) > length(paramsB)
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


  defp choose_media_type(conn, state, []) do
    not_acceptable(conn, state)
  end

  defp choose_media_type(conn, %{content_types_p: cTP} = state, [mediaType | tail]) do
    match_media_type(conn, state, tail, cTP, mediaType)
  end


  defp match_media_type(conn, state, accept, [], _mediaType) do
    choose_media_type(conn, state, accept)
  end

  defp match_media_type(conn, state, accept, cTP, mediaType = {{"*", "*", _params_A}, _qA, _aPA}) do
    match_media_type_params(conn, state, accept, cTP, mediaType)
  end

  defp match_media_type(conn, state, accept, cTP = [{{type, subType_P, _pP}, _fun} | _tail], mediaType = {{type, subType_A, _pA}, _qA, _aPA}) when subType_P === subType_A or subType_A === "*" do
    match_media_type_params(conn, state, accept, cTP, mediaType)
  end

  defp match_media_type(conn, state, accept, [_any | tail], mediaType) do
    match_media_type(conn, state, accept, tail, mediaType)
  end


  defp match_media_type_params(conn, state, _accept, [provided = {{tP, sTP, %{}}, _fun} | _tail], {{_tA, _sTA, params_A}, _qA, _aPA}) do
    pMT = {tP, sTP, params_A}
    conn
    |> put_resp_content_type(print_media_type(pMT))
    |> languages_provided(%{state | content_type_a: provided})
  end

  defp match_media_type_params(conn, state, accept, [provided = {pMT = {_tP, _sTP, params_P}, _fun} | tail], mediaType = {{_tA, _sTA, params_A}, _qA, _aPA}) do
    case :lists.sort(params_P) === :lists.sort(params_A) do
      true ->
        conn
        |> put_resp_content_type(print_media_type(pMT))
        |> languages_provided(%{state | content_type_a: provided})
      false ->
        match_media_type(conn, state, accept, tail, mediaType)
    end
  end


  defp languages_provided(conn, state) do
    case call(conn, state, :languages_provided) do
      :no_call ->
        charsets_provided(conn, state)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {[], conn2, handler_state} ->
        not_acceptable(conn2, %{state | handler_state: handler_state})
      {lP, conn2, handler_state} ->
        state2 = %{state | handler_state: handler_state, languages_p: lP}
        case get_req_header(conn2, "accept-language") do
          [] ->
            set_language(conn2, %{state2 | language_a: hd(lP)})
          acceptLanguage ->
            acceptLanguage2 = prioritize_languages(acceptLanguage)
            choose_language(conn2, state2, acceptLanguage2)
        end
    end
  end


  defp prioritize_languages(accept_languages) do
    accept_languages
    |> parse_language_header
    |> reformat_languages_for_cowboy_rest
    |> Enum.sort(fn {_tagA, qualityA}, {_tagB, qualityB} -> qualityA > qualityB end)
  end


  defp choose_language(conn, state, []) do
    not_acceptable(conn, state)
  end

  defp choose_language(conn, %{languages_p: lP} = state, [language | tail]) do
    match_language(conn, state, tail, lP, language)
  end


  defp match_language(conn, state, accept, [], _language) do
    choose_language(conn, state, accept)
  end

  defp match_language(conn, state, _accept, [provided | _tail], {:*, _quality}) do
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


  defp set_language(conn, %{language_a: language} = state) do
    conn
    |> put_resp_header("content-language", language)
    |> charsets_provided(state)
  end


  defp charsets_provided(conn, state) do
    case call(conn, state, :charsets_provided) do
      :no_call ->
        set_content_type(conn, state)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {[], conn2, handler_state} ->
        not_acceptable(conn2, %{state | handler_state: handler_state})
      {cP, conn2, handler_state} ->
        state2 = %{state | handler_state: handler_state, charsets_p: cP}
        case get_req_header(conn2, "accept-charset") do
          [] ->
            set_content_type(conn2, %{state2 | charset_a: hd(cP)})
          acceptCharset ->
            acceptCharset2 = prioritize_charsets(acceptCharset)
            choose_charset(conn2, state2, acceptCharset2)
        end
    end
  end


  defp prioritize_charsets(acceptCharsets) do
    acceptCharsets2 = :lists.sort(fn {_charsetA, qualityA}, {_charsetB, qualityB} -> qualityA > qualityB end, acceptCharsets)
    case :lists.keymember("*", 1, acceptCharsets2) do
      true ->
        acceptCharsets2
      false ->
        case :lists.keymember("iso-8859-1", 1, acceptCharsets2) do
          true ->
            acceptCharsets2
          false ->
            [{"iso-8859-1", 1000} | acceptCharsets2]
        end
    end
  end


  defp choose_charset(conn, state, []) do
    not_acceptable(conn, state)
  end

  defp choose_charset(conn, %{charsets_p: cP} = state, [charset | tail]) do
    match_charset(conn, state, tail, cP, charset)
  end


  defp match_charset(conn, state, accept, [], _charset) do
    choose_charset(conn, state, accept)
  end

  defp match_charset(conn, state, _accept, [provided | _], {provided, _}) do
    set_content_type(conn, %{state | charset_a: provided})
  end

  defp match_charset(conn, state, accept, [_ | tail], charset) do
    match_charset(conn, state, accept, tail, charset)
  end


  defp set_content_type(conn, %{content_type_a: {{type, subType, params}, _fun}, charset_a: charset} = state) do
    paramsBin = set_content_type_build_params(params, [])
    content_type = [type, "/", subType, paramsBin]
    content_type2 = case charset do
      :undefined ->
        content_type
      ^charset ->
        [content_type, "; charset=", charset]
    end
    conn
    |> put_resp_content_type(print_media_type(content_type2))
    |> encodings_provided(state)
  end


  defp set_content_type_build_params(%{}, []) do
    <<>>
  end

  defp set_content_type_build_params([], []) do
    <<>>
  end

  defp set_content_type_build_params([], acc) do
    :lists.reverse(acc)
  end

  defp set_content_type_build_params([{attr, value} | tail], acc) do
    set_content_type_build_params(tail, [[attr, "=", value], ";" | acc])
  end


  defp encodings_provided(conn, state) do
    variances(conn, state)
  end


  defp not_acceptable(conn, state) do
    respond(conn, state, 406)
  end


  defp variances(conn, %{content_types_p: cTP, languages_p: lP, charsets_p: cP} = state) do
    var_variances = case cTP do
      [] ->
        []
      [_] ->
        []
      [_ | _] ->
        ["accept"]
    end
    variances2 = case lP do
      [] ->
        var_variances
      [_] ->
        var_variances
      [_ | _] ->
        ["accept-language" | var_variances]
    end
    variances3 = case cP do
      [] ->
        variances2
      [_] ->
        variances2
      [_ | _] ->
        ["accept-charset" | variances2]
    end
    try() do
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
      {handlerVariances, conn2, handler_state} ->
        {var_variances ++ handlerVariances, conn2, %{state | handler_state: handler_state}}
    end
  end


  defp resource_exists(conn, state) do
    expect(conn, state, :resource_exists, true, &if_match_exists/2, &if_match_must_not_exist/2)
  end


  defp if_match_exists(conn, state) do
    state2 = %{state | exists: true}
    case get_req_header(conn, "if-match") do
      [] ->
        if_unmodified_since_exists(conn, state2)
      :* ->
        if_unmodified_since_exists(conn, state2)
      eTagsList ->
        if_match(conn, state2, eTagsList)
    end
  end


  defp if_match(conn, state, etagsList) do
    try() do
      case generate_etag(conn, state) do
        {{:weak, _}, conn2, state2} ->
          precondition_failed(conn2, state2)
        {etag, conn2, state2} ->
          case :lists.member(etag, etagsList) do
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


  defp if_match_must_not_exist(conn, state) do
    case get_req_header(conn, "if-match") do
      [] ->
        is_put_to_missing_resource(conn, state)
      _ ->
        precondition_failed(conn, state)
    end
  end


  defp if_unmodified_since_exists(conn, state) do
    try() do
      case get_req_header(conn, "if-unmodified-since") do
        [] ->
          if_none_match_exists(conn, state)
        ifUnmodifiedSince ->
          if_unmodified_since(conn, state, ifUnmodifiedSince)
      end
    catch
      _, _ ->
        if_none_match_exists(conn, state)
    end
  end


  defp if_unmodified_since(conn, state, ifUnmodifiedSince) do
    try() do
      last_modified(conn, state)
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :last_modified)
    else
      {lastModified, conn2, state2} ->
        case lastModified > ifUnmodifiedSince do
          true ->
            precondition_failed(conn2, state2)
          false ->
            if_none_match_exists(conn2, state2)
        end
    end
  end


  defp if_none_match_exists(conn, state) do
    case get_req_header(conn, "if-none-match") do
      [] ->
        if_modified_since_exists(conn, state)
      :* ->
        precondition_is_head_get(conn, state)
      etagsList ->
        if_none_match(conn, state, etagsList)
    end
  end


  defp if_none_match(conn, state, etagsList) do
    try() do
      generate_etag(conn, state)
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    else
      {etag, conn2, state2} ->
        case etag do
          :undefined ->
            precondition_failed(conn2, state2)
          ^etag ->
            case is_weak_match(etag, etagsList) do
              true ->
                precondition_is_head_get(conn2, state2)
              false ->
                method(conn2, state2)
            end
        end
    end
  end


  defp is_weak_match(_, []) do
    false
  end

  defp is_weak_match({_, tag}, [{_, tag} | _]) do
    true
  end

  defp is_weak_match(etag, [_ | tail]) do
    is_weak_match(etag, tail)
  end


  defp precondition_is_head_get(conn, %{method: var_method} = state) when var_method === "HEAD" or var_method === "GET" do
    not_modified(conn, state)
  end

  defp precondition_is_head_get(conn, state) do
    precondition_failed(conn, state)
  end


  defp if_modified_since_exists(conn, state) do
    try() do
      case get_req_header(conn, "if-modified-since") do
        [] ->
          method(conn, state)
        ifModifiedSince ->
          if_modified_since_now(conn, state, ifModifiedSince)
      end
    catch
      _, _ ->
        method(conn, state)
    end
  end


  defp if_modified_since_now(conn, state, ifModifiedSince) do
    case ifModifiedSince > :erlang.universaltime() do
      true ->
        method(conn, state)
      false ->
        if_modified_since(conn, state, ifModifiedSince)
    end
  end


  defp if_modified_since(conn, state, ifModifiedSince) do
    try() do
      case last_modified(conn, state) do
        {:no_call, conn2, state2} ->
          method(conn2, state2)
        {lastModified, conn2, state2} ->
          case lastModified > ifModifiedSince do
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


  defp not_modified(conn, state) do
    conn2 = delete_resp_header(conn, "content-type")
    try() do
      case set_resp_etag(conn2, state) do
        {conn3, state2} ->
          try() do
            set_resp_expires(conn3, state2)
          catch
            class, reason ->
              error_terminate(conn, state2, class, reason, :expires)
          else
            {req4, state3} ->
              respond(req4, state3, 304)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    end
  end


  defp precondition_failed(conn, state) do
    respond(conn, state, 412)
  end


  defp is_put_to_missing_resource(conn, %{method: "PUT"} = state) do
    moved_permanently(conn, state, &is_conflict/2)
  end

  defp is_put_to_missing_resource(conn, state) do
    previously_existed(conn, state)
  end


  defp moved_permanently(conn, state, onFalse) do
    case call(conn, state, :moved_permanently) do
      {{true, location}, conn2, handler_state} ->
        conn3 = put_resp_header(conn2, "location", location)
        respond(conn3, %{state | handler_state: handler_state}, 301)
      {false, conn2, handler_state} ->
        onFalse.(conn2, %{state | handler_state: handler_state})
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      :no_call ->
        onFalse.(conn, state)
    end
  end


  defp previously_existed(conn, state) do
    expect(conn, state, :previously_existed, false, fn r, s -> is_post_to_missing_resource(r, s, 404) end, fn r, s -> moved_permanently(r, s, &moved_temporarily/2) end)
  end


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


  defp is_post_to_missing_resource(conn, %{method: "POST"} = state, onFalse) do
    allow_missing_post(conn, state, onFalse)
  end

  defp is_post_to_missing_resource(conn, state, onFalse) do
    respond(conn, state, onFalse)
  end


  defp allow_missing_post(conn, state, onFalse) do
    expect(conn, state, :allow_missing_post, true, &accept_resource/2, onFalse)
  end


  defp method(conn, %{method: "DELETE"} = state) do
    delete_resource(conn, state)
  end

  defp method(conn, %{method: "PUT"} = state) do
    is_conflict(conn, state)
  end

  defp method(conn, %{method: var_method} = state) when var_method === "POST" or var_method === "PATCH" do
    accept_resource(conn, state)
  end

  defp method(conn, %{method: var_method} = state) when var_method === "GET" or var_method === "HEAD" do
    set_resp_body_etag(conn, state)
  end

  defp method(conn, state) do
    multiple_choices(conn, state)
  end


  defp delete_resource(conn, state) do
    expect(conn, state, :delete_resource, false, 500, &delete_completed/2)
  end


  defp delete_completed(conn, state) do
    expect(conn, state, :delete_completed, true, &has_resp_body/2, 202)
  end


  defp is_conflict(conn, state) do
    expect(conn, state, :is_conflict, false, &accept_resource/2, 409)
  end


  defp accept_resource(conn, state) do
    case call(conn, state, :content_types_accepted) do
      :no_call ->
        respond(conn, state, 415)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {cTA, conn2, handler_state} ->
        cTA2 = for(p <- cTA, into: [], do: normalize_content_types(p))
        state2 = %{state | handler_state: handler_state}
        try() do
          case get_req_header(conn2, "content-type") do
            content_type ->
              choose_content_type(conn2, state2, content_type, cTA2)
          end
        catch
          _, _ ->
            respond(conn2, state2, 415)
        end
    end
  end


  defp choose_content_type(conn, state, _content_type, []) do
    respond(conn, state, 415)
  end

  defp choose_content_type(conn, state, content_type, [{accepted, fun} | _tail]) when accepted === :* or accepted === content_type do
    process_content_type(conn, state, fun)
  end

  defp choose_content_type(conn, state, {type, subType, param}, [{{type, subType, acceptedParam}, fun} | _tail]) when acceptedParam === :* or acceptedParam === param do
    process_content_type(conn, state, fun)
  end

  defp choose_content_type(conn, state, content_type, [_any | tail]) do
    choose_content_type(conn, state, content_type, tail)
  end


  defp process_content_type(conn, %{method: var_method, exists: exists} = state, fun) do
    try() do
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
        {{true, resURL}, conn2, handler_state2} when var_method === "POST" ->
          state2 = %{state | handler_state: handler_state2}
          conn3 = put_resp_header(conn2, "location", resURL)
          case :if do
            :if when exists ->
              respond(conn3, state2, 303)
            :if when true ->
              respond(conn3, state2, 201)
          end
      end
    catch
      class, reason = {:case_clause, :no_call} ->
        error_terminate(conn, state, class, reason, fun)
    end
  end


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


  defp has_resp_body(conn, state) do
    case conn.resp_body do
      nil ->
        respond(conn, state, 204)
      _ ->
        multiple_choices(conn, state)
    end
  end


  defp set_resp_body_etag(conn, state) do
    try() do
      case set_resp_etag(conn, state) do
        {conn2, state2} ->
          set_resp_body_last_modified(conn2, state2)
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :generate_etag)
    end
  end


  defp set_resp_body_last_modified(conn, state) do
    try() do
      case last_modified(conn, state) do
        {lastModified, conn2, state2} ->
          case lastModified do
            ^lastModified when is_atom(lastModified) ->
              set_resp_body_expires(conn2, state2)
            ^lastModified ->
              lastModifiedBin = :cowboy_clock.rfc1123(lastModified)
              conn3 = put_resp_header(conn2, "last-modified", lastModifiedBin)
              set_resp_body_expires(conn3, state2)
          end
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :last_modified)
    end
  end


  defp set_resp_body_expires(conn, state) do
    try() do
      case set_resp_expires(conn, state) do
        {conn2, state2} ->
          set_resp_body(conn2, state2)
      end
    catch
      class, reason ->
        error_terminate(conn, state, class, reason, :expires)
    end
  end


  defp set_resp_body(conn, %{content_type_a: {_, callback}} = state) do
    try() do
      case call(conn, state, callback) do
        {:stop, conn2, handler_state2} ->
          terminate(conn2, %{state | handler_state: handler_state2})
        {body, conn2, handler_state2} ->
          state2 = %{state | handler_state: handler_state2, body: body}
          multiple_choices(conn2, state2)
      end
    catch
      class, reason = {:case_clause, :no_call} ->
        error_terminate(conn, state, class, reason, callback)
    end
  end


  defp multiple_choices(conn, state) do
    expect(conn, state, :multiple_choices, false, 200, 300)
  end


  defp set_resp_etag(conn, state) do
    {etag, conn2, state2} = generate_etag(conn, state)
    case etag do
      :undefined ->
        {conn2, state2}
      ^etag ->
        conn3 = put_resp_header(conn2, "etag", encode_etag(etag))
        {conn3, state2}
    end
  end


  @spec encode_etag({:strong | :weak, binary()}) :: iolist()


  defp encode_etag({:strong, etag}) do
    [?", etag, ?"]
  end

  defp encode_etag({:weak, etag}) do
    ['W/"', etag, ?"]
  end


  defp set_resp_expires(conn, state) do
    {var_expires, conn2, state2} = expires(conn, state)
    case var_expires do
      ^var_expires when is_atom(var_expires) ->
        {conn2, state2}
      ^var_expires when is_binary(var_expires) ->
        conn3 = put_resp_header(conn2, "expires", var_expires)
        {conn3, state2}
      ^var_expires ->
        expiresBin = :cowboy_clock.rfc1123(var_expires)
        conn3 = put_resp_header(conn2, "expires", expiresBin)
        {conn3, state2}
    end
  end


  defp generate_etag(conn, %{etag: :no_call} = state) do
    {:undefined, conn, state}
  end

  defp generate_etag(conn, %{etag: :undefined} = state) do
    case unsafe_call(conn, state, :generate_etag) do
      :no_call ->
        {:undefined, conn, %{state | etag: :no_call}}
      {etag, conn2, handler_state} when is_binary(etag) ->
        etag2 = :cowboy_http.entity_tag_match(etag)
        {etag2, conn2, %{state | handler_state: handler_state, etag: etag2}}
      {etag, conn2, handler_state} ->
        {etag, conn2, %{state | handler_state: handler_state, etag: etag}}
    end
  end

  defp generate_etag(conn, %{etag: etag} = state) do
    {etag, conn, state}
  end


  defp last_modified(conn, %{last_modified: :no_call} = state) do
    {:undefined, conn, state}
  end

  defp last_modified(conn, %{last_modified: :undefined} = state) do
    case unsafe_call(conn, state, :last_modified) do
      :no_call ->
        {:undefined, conn, %{state | last_modified: :no_call}}
      {lastModified, conn2, handler_state} ->
        {lastModified, conn2, %{state | handler_state: handler_state, last_modified: lastModified}}
    end
  end

  defp last_modified(conn, %{last_modified: lastModified} = state) do
    {lastModified, conn, state}
  end


  defp expires(conn, %{expires: :no_call} = state) do
    {:undefined, conn, state}
  end

  defp expires(conn, %{expires: :undefined} = state) do
    case unsafe_call(conn, state, :expires) do
      :no_call ->
        {:undefined, conn, %{state | expires: :no_call}}
      {var_expires, conn2, handler_state} ->
        {var_expires, conn2, %{state | handler_state: handler_state, expires: var_expires}}
    end
  end

  defp expires(conn, %{expires: var_expires} = state) do
    {var_expires, conn, state}
  end


  @callback test(conn, state) :: {[binary()], conn, state}
            when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [test: 2]

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

  defp terminate(conn, state) do
    conn |> send_resp(conn.status, state.body)
  end

  defp error_terminate(conn, _state, _class, reason, _callback) do
    conn |> send_resp(500, reason)
  end
end
