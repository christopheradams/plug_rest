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

        def init(conn, state) do
          {:ok, conn, state}
        end

        def allowed_methods(conn, state) do
          {["GET"], conn, state}
        end

        def resource_exists(%{params: params} = conn, _state)
          username = params["username"]
          # Look up user
          state = %{name: "John Doe", username: username}
          {true, conn, state}
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
      allow_missing_post     : false
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
  * `{:chunked, Enum.t}`, which will use `send_chunked/2`
  * `{:file, binary()}`, which will use `send_file/3`

  You can halt the resource handling from any callback and return a manual
  response like so:

      response = send_resp(conn, status_code, resp_body)
      {:stop, response, state}

  The content accepted handlers defined in `content_types_accepted` will be
  called for POST, PUT, and PATCH requests. By default, the response body will
  be empty. If desired, you can set the response body like so:

      conn2 = put_rest_body(conn, "#{conn.method} was successful")
      {true, conn2, state}

  ## Configuration

  You can change some defaults by configuring the `:plug_rest` app in
  your `config.exs` file.

  To change the default `known_methods` for all Resources:

      config :plug_rest,
        known_methods: ["GET", "HEAD", "OPTIONS", "TRACE"]

  If a Resource implements the `known_methods` callback, that list
  always takes precedence over the default list.

  ## Plug Pipeline

  You can create a custom Plug pipeline within your resource using `Plug.Builder`:

      defmodule MessageResource do
        use PlugRest.Resource

        # Add the Builder to your resource
        use Plug.Builder

        # Add your custom plugs
        plug :hello

        # Finally, call the :rest plug to start executing the REST callbacks
        plug :rest

        # REST Callbacks
        def to_html(conn, state) do
          {conn.private.message, conn, state}
        end

        # Example custom plug function
        def hello(conn, _opts) do
          put_private(conn, :message, "Hello")
        end
      end
  """

  import PlugRest.Utils
  import PlugRest.Conn
  import Plug.Conn

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour PlugRest.Resource

      import Plug.Conn
      import PlugRest.Resource, only: [put_rest_body: 2, get_rest_body: 1]

      @doc false
      def init(options) do
        options
      end

      @doc false
      def call(conn, options) do
        rest(conn, options)
      end

      @doc false
      def rest(conn, options) do
        PlugRest.Resource.upgrade(conn, __MODULE__, options)
      end

      defoverridable [init: 1, call: 2]
    end
  end

  @typedoc "A Module adopting the `PlugRest.Resource` behaviour"
  @type resource :: atom

  @typedoc "A `%Plug.Conn{}` struct representing the connection"
  @type conn :: Plug.Conn.t

  @typedoc "The state of the resource"
  @type state :: any

  @typep rest_state :: PlugRest.State.t

  @typedoc "The callback accepting a representation of the resource for a content-type"
  @type accept_resource :: atom

  @typedoc "The callback providing a representation of the resource for a content-type"
  @type provide_resource :: atom

  @typedoc "A representation of a content-type match"
  @type media_type :: {binary, binary, %{binary => binary} | :*}

  @typedoc "A content-type accepted handler, comprising a media type and acccept callback"
  @type content_type_a :: {binary() | media_type, accept_resource}

  @typedoc "A content-type provided handler, comprising a media type and provide callback"
  @type content_type_p :: {binary() | media_type, provide_resource}

  @typedoc "An HTTP method written in uppercase"
  @type method :: binary

  @typedoc "A language tag written in lowercase"
  @type language :: binary

  @typedoc "A charset written in lowercase"
  @type charset :: binary

  @typedoc "The name of an HTTP header"
  @type header_name :: binary

  @typedoc "A WWW-Authenticate header value"
  @type auth_head :: binary

  @typedoc "A URI"
  @type uri :: binary

  @typep content_handler :: PlugRest.State.content_handler

  @typedoc """
  An entity tag

  ## Examples
      # ETag: W/"etag-header-value"
      {:weak, "etag-header-value"}

      # ETag: "etag-header-value"
      {:strong, "etag-header-value"}

      # ETag: "etag-header-value"
      {"\\"etag-header-value\\""}
  """
  @type etag :: binary | {:weak | :strong, binary}

  @typep etag_tuple :: {:weak | :strong, binary}
  @typep etags_list :: PlugRest.Conn.etags_list
  @typep priority_type :: PlugRest.Conn.priority_type
  @typep quality_type :: PlugRest.Conn.quality_type

  @typep status_code :: 200..503

  @default_media_type {"text", "html", %{}}
  @default_content_handler {@default_media_type, :to_html}

  ## Common handler callbacks

  @doc """
  Sets up the connection and handler state before other REST callbacks

  - Methods: all
  - Default: `:ok`

  ## Examples

        def init(conn, state) do
          {:ok, conn, state}
        end
  """
  @callback init(conn, state) :: {:ok, conn, state}
                               | {:stop, conn, state}
  @optional_callbacks [init: 2]

  ## REST handler callbacks

  @doc """
  Returns the list of allowed methods

  - Methods: all
  - Default: `["GET", "HEAD", "OPTIONS"]`

  Methods are case sensitive and should be given in uppercase.

  If the request uses a method that is not allowed, the resource will
  respond `405 Method Not Allowed`.

  ## Examples

      def allowed_methods(conn, state) do
        {["GET,", "HEAD", "OPTIONS"], conn, state}
      end
  """
  @callback allowed_methods(conn, state) :: {[method], conn, state}
                                          | {:stop, conn, state}
  @optional_callbacks [allowed_methods: 2]

  @doc """
  Returns whether POST is allowed when the resource doesn't exist

  - Methods: POST
  - Default: `false`

  This function will be called when `resource_exists` is `false` and
  the request method is POST. Returning `true` means the missing
  resource can process the enclosed representation, and the resource's
  content accepted handler will be invoked.

  Returning `true` means POST should update an existing resource and
  create one if it is missing.

  Returning `false` means POST to a missing resource will send `404
  Not Found`.

  ## Examples

      def allow_missing_post(conn, state) do
        {true, conn, state}
      end
  """
  @callback allow_missing_post(conn, state) :: {boolean(), conn, state}
                                             | {:stop, conn, state}
  @optional_callbacks [allow_missing_post: 2]

  @doc """
  Returns the list of charsets the resource provides

  - Methods:  GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: Skip to the next step if undefined.

  The list must be ordered by priority.

  The first charset will be chosen if the client does not send an
  accept-charset header, or the first that matches.

  The charset should be returned as a lowercase string.

  ## Examples

      def charsets_provided(conn, state) do
        {["utf-8"], conn, state}
      end
  """
  @callback charsets_provided(conn, state) :: {[charset], conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [charsets_provided: 2]

  @doc """
  Returns the list of content-types the resource accepts

  - Methods: POST, PUT, PATCH
  - Default: Crash if undefined.

  The list must be ordered by priority.

  Each content-type can be given either as a string like
  `"text/html"`; or a tuple in the form `{type, subtype, params}`,
  where params can be `%{}` (no params acceptable), `:*` (all params
  acceptable), or a map of acceptable params `%{"level" => "1"}`.

  If no content types match, a `415 Unsupported Media Type` response
  will be sent.

  ## Examples

      def content_types_accepted(conn, state) do
        {[{"application/json", :from_json}], conn, state}
      end

  The content accepted handler value is the name of the callback that
  will be called if the content-type matches. It is defined as
  follows.

  - Value type: `true | {true, URL} | false`
  - Default: Crash if undefined.

  Process the request body

  This function should create or update the resource based on the
  request body and the method used. Consult the `Plug.Conn` and
  `Plug.Parsers` docs for information on parsing and reading the
  request body params.

  Returning `true` means the process was successful. Returning `{true,
  URL}` means a new resource was created at that location.

  Returning `false` will send a `400 Bad Request` response.

  If a response body must be sent, the appropriate media-type, charset
  and language can be manipulated using `Plug.Conn`. The body can be
  set using `put_rest_body/2`.

  ## Examples

      # post accepted
      def from_json(conn, :success = state) do
        conn = put_rest_body(conn, "{\\"status\\": \\"ok\\"}")
        {true, conn, state}
      end

      # post create and redirect
      def from_json(conn, :redirect = state) do
        {{true, "new_url/1234"}, conn, state}
      end

      # post error
      def from_json(conn, :error = state) do
        {false, conn, state}
      end
  """
  @callback content_types_accepted(conn, state) :: {[content_type_a], conn, state}
                                                 | {:stop, conn, state}
  @optional_callbacks [content_types_accepted: 2]

  @doc """
  Returns the list of content-types the resource provides

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `[{{"text", "html", %{}}, :to_html}]`

  The list must be ordered by priority.

  Each content-type can be given either as a string like
  `"text/html"`; or a tuple in the form `{type, subtype, params}`,
  where params can be `%{}` (no params acceptable), `:*` (all params
  acceptable), or a map of acceptable params `%{"level" => "1"}`.

  PlugRest will choose the content-type through content negotiation
  with the client.

  If content negotiation fails, a `406 Not Acceptable` response will
  be sent.

  ## Examples

      def content_types_provided(conn, state) do
        {[{"application/json", :to_json}], conn, state}
      end

  The content provided handler names a function that will return a
  representation of the resource using that content-type. It is
  defined as follows.

  - Methods: GET, HEAD
  - Value type: `binary() | {:chunked, Enum.t} | {:file, binary()}`
  - Default: Crash if undefined.

  Return the response body.

  ## Examples

      def to_json(conn, state) do
        {"{}", conn, state}
      end
  """
  @callback content_types_provided(conn, state) :: {[content_type_p], conn, state}
                                                 | {:stop, conn, state}
  @optional_callbacks [content_types_provided: 2]

  @doc """
  Returns whether the delete action has been completed

  - Methods: DELETE
  - Default: `true`

  This function is called after a successful `delete_resource`.
  Returning `true` means the delete has completed. Returning `false`
  means the request was accepted but may not have finished, and
  responds with `202 Accepted`.

  ## Examples

      def delete_completed(conn, state) do
        {true, conn, state}
      end
  """
  @callback delete_completed(conn, state) :: {boolean(), conn, state}
                                           | {:stop, conn, state}
  @optional_callbacks [delete_completed: 2]

  @doc """
  Deletes the resource

  - Methods: DELETE
  - Default: `false`

  Returning `true` means the delete request can be enacted. Returning
  `false` will send a `500` error.

  ## Examples

      def delete_resource(conn, state) do
        {true, conn, state}
      end
  """
  @callback delete_resource(conn, state) :: {boolean(), conn, state}
                                          | {:stop, conn, state}
  @optional_callbacks [delete_resource: 2]

  @doc """
  Returns the date of expiration of the resource

  - Methods: GET, HEAD
  - Default: `nil`

  This date will be sent as the value of the expires header. The date
  can be specified as a `datetime()` tuple or a string.

  ## Examples

      def expires(conn, state) do
        {{{2012, 9, 21}, {22, 36, 14}}, conn, state}
      end
  """
  @callback expires(conn, state) :: {:calendar.datetime() | binary() | nil, conn, state}
                                  | {:stop, conn, state}
  @optional_callbacks [expires: 2]

  @doc """
  Returns whether access to the resource is forbidden

  - Methods: all
  - Default: `false`

  Returning `true` will send a `403 Forbidden` response.

  ## Examples

      def forbidden(conn, state) do
        {false, conn, state}
      end
  """
  @callback forbidden(conn, state) :: {boolean(), conn, state}
                                    | {:stop, conn, state}
  @optional_callbacks [forbidden: 2]

  @doc """
  Returns the entity tag of the resource

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `nil`

  This value will be sent as the value of the etag header.

  ## Examples

      # ETag: W/"etag-header-value"
      def generate_etag(conn, state) do
        {{:weak, "etag-header-value"}, conn, state}
      end

      # ETag: "etag-header-value"
      def generate_etag(conn, state) do
        {{:strong, "etag-header-value"}, conn, state}
      end

      # ETag: "etag-header-value"
      def generate_etag(conn, state) do
        {"\\"etag-header-value\\""}, conn, state}
      end
  """
  @callback generate_etag(conn, state) :: {etag, conn, state}
                                        | {nil, conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [generate_etag: 2]

  @doc """
  Returns whether the user is authorized to perform the action

  - Methods: all
  - Default: `true`

  Returning `{false, binary()}` will send a `401 Unauthorized`
  response. The value of the `binary()` will be set as the
  WWW-authenticate header.

  ## Examples

      def is_authorized(conn, state) do
        {true, conn, state}
      end
  """
  @callback is_authorized(conn, state) :: {true | {false, auth_head}, conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [is_authorized: 2]

  @doc """
  Returns whether the PUT action results in a conflict

  - Methods: PUT
  - Default: `false`

  Returning `true` will send a `409 Conflict` response.

  ## Examples

      def is_conflict(conn, state) do
        {false, conn, state}
      end
  """
  @callback is_conflict(conn, state) :: {boolean(), conn, state}
                                      | {:stop, conn, state}
  @optional_callbacks [is_conflict: 2]

  @doc """
  Returns the list of known methods

  - Methods: all
  - Default: `["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]`

  Specifies the full list of HTTP methods known by the server, even if
  they aren't allowed in this resource.

  The default list can be configured in `config.exs`:

      config :plug_rest,
        known_methods: ["GET", "HEAD", "OPTIONS", "TRACE"]

  If a Resource implements the `known_methods` callback, that list
  always takes precedence over the default list.

  Methods are case sensitive and should be given in uppercase.

  ## Examples

      def known_methods(conn, state) do
        {["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
         conn, state}
      end
  """
  @callback known_methods(conn, state) :: {[method], conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [known_methods: 2]

  @doc """
  Returns the list of languages the resource provides

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: Skip to the next step if undefined.

  The first language will be chosen if the client does not send an
  accept-language header, or the first that matches.

  The language should be returned as a lowercase binary.

  ## Examples

      def languages_provided(conn, state) do
        {["en"], conn, state}
      end
  """
  @callback languages_provided(conn, state) :: {[language], conn, state}
                                             | {:stop, conn, state}
  @optional_callbacks [languages_provided: 2]

  @doc """
  Returns the date of last modification of the resource

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `nil`

  Returning a `datetime()` tuple will set the last-modified header and
  be used for comparison in conditional if-modified-since and
  if-unmodified-since requests.

  ## Examples

      def last_modified(conn, state) do
        {{{2012, 9, 21}, {22, 36, 14}}, conn, state}
      end
  """
  @callback last_modified(conn, state) :: {:calendar.datetime(), conn, state}
                                        | {nil, conn, state}
                                        | {:stop, conn, state}
  @optional_callbacks [last_modified: 2]

  @doc """
  Returns whether the request is malformed

  - Methods: all
  - Default: `false`

  Returning true will send a `400 Bad Request` response.

  ## Examples

      def malformed_request(conn, state) do
        {false, conn, state}
      end
  """
  @callback malformed_request(conn, state) :: {boolean(), conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [malformed_request: 2]

  @doc """
  Returns whether the resource was permanently moved

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `false`

  Returning `{true, URI}` will send a `301 Moved Permanently` response
  with the URI in the Location header.

  ## Examples

      def moved_permanently(conn, state) do
        {{true, "/new_location"}, conn, state}
      end
  """
  @callback moved_permanently(conn, state) :: {{true, uri} | false, conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [moved_permanently: 2]

  @doc """
  Returns whether the resource was temporarily moved

  - Methods: GET, HEAD, POST, PATCH, DELETE
  - Default: `false`

  Returning `{true, URI}` will send a `307 Temporary Redirect`
  response with the URI in the Location header.

  ## Examples

      def moved_temporarily(conn, state) do
        {{true, "/new_location"}, conn, state}
      end
  """
  @callback moved_temporarily(conn, state) :: {{true, uri} | false, conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [moved_temporarily: 2]

  @doc """
  Returns whether there are multiple representations of the resource

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `false`

  Returning `true` means that multiple representations of the resource
  are possible and one cannot be chosen automatically. This will send
  a `300 Multiple Choices` response. The response body should include
  information about the different representations using
  `set_rest_body/2`. The content-type that was already negotiated can
  be retrieved by calling:

      [content-type] = get_resp_header(conn, "content-type")

  ## Examples

      def multiple_choices(conn, state) do
        {false, conn, state}
      end
  """
  @callback multiple_choices(conn, state) :: {boolean(), conn, state}
                                           | {:stop, conn, state}
  @optional_callbacks [multiple_choices: 2]

  @doc """
  Handles a request for information

  - Methods: OPTIONS
  - Default: `true`

  The response should inform the client the communication options
  available for this resource.

  By default, PlugRest will send a `200 OK` response with the list of
  supported methods in the Allow header.

  ## Examples

      def options(conn, state) do
        {:ok, conn, state}
      end
  """
  @callback options(conn, state) :: {:ok, conn, state}
                                  | {:stop, conn, state}
  @optional_callbacks [options: 2]

  @doc """
  Returns whether the resource existed previously

  - Methods: GET, HEAD, POST, PATCH, DELETE
  - Default: `false`

  Returning `true` will invoke `moved_permanently` and
  `moved_temporarily` to determine whether to send a `301 Moved
  Permanently`, `307 Temporary Redirect`, or `410 Gone` response.

  ## Examples

      def previously_existed(conn, state) do
        {false, conn, state}
      end
  """
  @callback previously_existed(conn, state) :: {boolean(), conn, state}
                                             | {:stop, conn, state}
  @optional_callbacks [previously_existed: 2]

  @doc """
  Returns whether the resource exists

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `true`

  Returning `false` will send a `404 Not Found` response, unless the
  method is POST and `allow_missing_post` is true.

  ## Examples

      def resource_exists(conn, state) do
        {true, conn, state}
      end
  """
  @callback resource_exists(conn, state) :: {boolean(), conn, state}
                                          | {:stop, conn, state}
  @optional_callbacks [resource_exists: 2]

  @doc """
  Returns whether the service is available

  - Methods: all
  - Default: `true`

  Use this to confirm all backend systems are up.

  Returning `false` will send a `503 Service Unavailable` response.

  ## Examples

      def service_available(conn, state) do
        {true, conn, state}
      end
  """
  @callback service_available(conn, state) :: {boolean(), conn, state}
                                            | {:stop, conn, state}
  @optional_callbacks [service_available: 2]

  @doc """
  Returns whether the requested URI is too long

  - Methods: all
  - Default: `false`

  Returning `true` will send a `414 Request-URI Too Long` response.

  ## Examples

      def uri_too_long(conn, state) do
        {false, conn, state}
      end
  """
  @callback uri_too_long(conn, state) :: {boolean(), conn, state}
                                       | {:stop, conn, state}
  @optional_callbacks [uri_too_long: 2]

  @doc """
  Returns whether the content-* headers are valid

  - Methods: all
  - Default: `true`

  This functions should check for invalid or unknown content-*
  headers.

  Returning `false` will send a `501 Not Implemented` response.

  ## Examples

      def valid_content_headers(conn, state) do
        {true, conn, state}
      end
  """
  @callback valid_content_headers(conn, state) :: {boolean(), conn, state}
                                                | {:stop, conn, state}
  @optional_callbacks [valid_content_headers: 2]

  @doc """
  Returns whether the request body length is within acceptable boundaries

  - Methods: all
  - Default: `true`

  Returning `false` will send a `413 Request Entity Too Large`
  response.

  ## Examples

      def valid_entity_length(conn, state) do
        {true, conn, state}
      end
  """
  @callback valid_entity_length(conn, state) :: {boolean(), conn, state}
                                              | {:stop, conn, state}
  @optional_callbacks [valid_entity_length: 2]

  @doc """
  Return the list of headers that affect the representation of the resource

  - Methods: GET, HEAD, POST, PUT, PATCH, DELETE
  - Default: `[]`

  This function may return a list of strings saying which headers
  should be included in the response's Vary header.

  PlugRest will automatically add the Accept, Accept-language and
  Accept-charset headers to the list if the respective functions were
  defined in the resource.

  ## Examples

      # vary: user-agent
      def variances(conn, state) do
        {["user-agent"], conn, state}
      end
  """
  @callback variances(conn, state) :: {[header_name], conn, state}
                                    | {:stop, conn, state}
  @optional_callbacks [variances: 2]

  @doc """
  Executes the REST state machine with a connection and resource

  Accepts a `Plug.Conn` struct, a `PlugRest.Resource` module, and the
  initial state of the resource, and executes the REST state machine.
  """
  @spec upgrade(conn, resource, state) :: conn
  def upgrade(conn, resource, resource_state) do
    method = conn.method
    known_methods = Application.get_env(:plug_rest, :known_methods)

    state = %PlugRest.State{method: method, known_methods: known_methods,
                            handler: resource, handler_state: resource_state}

    expect(conn, state, :init, :ok, &service_available/2, 500)
  end

  @spec service_available(conn, rest_state) :: conn
  defp service_available(conn, state) do
    expect(conn, state, :service_available, true, &known_methods/2, 503)
  end

  @spec known_methods(conn, rest_state) :: conn
  defp known_methods(conn, %{method: var_method, known_methods: known_methods} = state) do
    case call(conn, state, :known_methods) do
      :no_call when is_list(known_methods) ->
        case Enum.member?(known_methods, var_method) do
          true -> next(conn, state, &uri_too_long/2)
          false -> next(conn, state, 501)
        end
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
        state2 = %{state | handler_state: handler_state, known_methods: list}
        case Enum.member?(list, var_method) do
          true ->
            next(conn2, state2, &uri_too_long/2)
          false ->
            next(conn2, state2, 501)
        end
    end
  end

  @spec uri_too_long(conn, rest_state) :: conn
  defp uri_too_long(conn, state) do
    expect(conn, state, :uri_too_long, false, &allowed_methods/2, 414)
  end

  @spec allowed_methods(conn, rest_state) :: conn
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

  @spec malformed_request(conn, rest_state) :: conn
  defp malformed_request(conn, state) do
    expect(conn, state, :malformed_request, false, &is_authorized/2, 400)
  end

  @spec is_authorized(conn, rest_state) :: conn
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

  @spec forbidden(conn, rest_state) :: conn
  defp forbidden(conn, state) do
    expect(conn, state, :forbidden, false, &valid_content_headers/2, 403)
  end

  @spec valid_content_headers(conn, rest_state) :: conn
  defp valid_content_headers(conn, state) do
    expect(conn, state, :valid_content_headers, true, &valid_entity_length/2, 501)
  end

  @spec valid_entity_length(conn, rest_state) :: conn
  defp valid_entity_length(conn, state) do
    expect(conn, state, :valid_entity_length, true, &options/2, 413)
  end

  @spec options(conn, rest_state) :: conn
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

  @spec content_types_provided(conn, rest_state) :: conn
  defp content_types_provided(conn, state) do
    case call(conn, state, :content_types_provided) do
      :no_call ->
        state2 = %{state | content_types_p: [@default_content_handler]}
        case parse_media_range_header(conn, "accept") do
          {:ok, []} ->
            conn
            |> put_resp_content_type(print_media_type(@default_media_type))
            |> languages_provided(%{state2 | content_type_a: @default_content_handler})
          {:ok, accept} ->
            choose_media_type(conn, state2, prioritize_accept(accept))
          :error ->
            respond(conn, state2, 400)
        end
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {[], conn2, handler_state} ->
        not_acceptable(conn2, %{state | handler_state: handler_state})
      {c_tp, conn2, handler_state} ->
        c_tp2 = for(p <- c_tp, into: [], do: normalize_content_types(p))
        state2 = %{state | handler_state: handler_state, content_types_p: c_tp2}
        case parse_media_range_header(conn2, "accept") do
          {:ok, []} ->
            {p_mt, _fun} = head_ctp = hd(c_tp2)
            conn2
            |> put_resp_content_type(print_media_type(p_mt))
            |> languages_provided(%{state2 | content_type_a: head_ctp})
          {:ok, accept} ->
            choose_media_type(conn2, state2, prioritize_accept(accept))
          :error ->
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

  @spec languages_provided(conn, rest_state) :: conn
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

  @spec set_language(conn, rest_state) :: conn
  defp set_language(conn, %{language_a: language} = state) do
    conn
    |> put_resp_header("content-language", language)
    |> charsets_provided(state)
  end

  @spec charsets_provided(conn, rest_state) :: conn
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

  @spec set_content_type(conn, rest_state) :: conn
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

  @spec encodings_provided(conn, rest_state) :: conn
  defp encodings_provided(conn, state) do
    variances(conn, state)
  end

  @spec not_acceptable(conn, rest_state) :: conn
  defp not_acceptable(conn, state) do
    respond(conn, state, 406)
  end

  @spec variances(conn, rest_state) :: conn
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
  end

  defp variances(conn, state, var_variances) do
    case unsafe_call(conn, state, :variances) do
      :no_call ->
        {var_variances, conn, state}
      {handler_variances, conn2, handler_state} ->
        {var_variances ++ handler_variances, conn2, %{state | handler_state: handler_state}}
    end
  end

  @spec resource_exists(conn, rest_state) :: conn
  defp resource_exists(conn, state) do
    expect(conn, state, :resource_exists, true, &if_match_exists/2, &if_match_must_not_exist/2)
  end

  @spec if_match_exists(conn, rest_state) :: conn
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
  end

  @spec if_match_must_not_exist(conn, rest_state) :: conn
  defp if_match_must_not_exist(conn, state) do
    case get_req_header(conn, "if-match") do
      [] ->
        is_put_to_missing_resource(conn, state)
      _ ->
        precondition_failed(conn, state)
    end
  end

  @spec if_unmodified_since_exists(conn, rest_state) :: conn
  defp if_unmodified_since_exists(conn, state) do
    case parse_date_header(conn, "if-unmodified-since") do
      [] ->
        if_none_match_exists(conn, state)
      if_unmodified_since ->
        if_unmodified_since(conn, state, if_unmodified_since)
    end
  end

  @spec if_unmodified_since(conn, state, :calendar.time) :: conn
  defp if_unmodified_since(conn, state, if_unmodified_since) do
    case last_modified(conn, state) do
      {last_modified, conn2, state2} ->
        case last_modified > if_unmodified_since do
          true ->
            precondition_failed(conn2, state2)
          false ->
            if_none_match_exists(conn2, state2)
        end
    end
  end

  @spec if_none_match_exists(conn, rest_state) :: conn
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
  end

  @spec is_weak_match(etag_tuple, [etag_tuple]) :: boolean()
  defp is_weak_match(_, []) do
    false
  end

  defp is_weak_match({_, tag}, [{_, tag} | _]) do
    true
  end

  defp is_weak_match(etag, [_ | tail]) do
    is_weak_match(etag, tail)
  end

  @spec precondition_is_head_get(conn, rest_state) :: conn
  defp precondition_is_head_get(conn, %{method: var_method} = state)
  when var_method === "HEAD" or var_method === "GET" do
    not_modified(conn, state)
  end

  defp precondition_is_head_get(conn, state) do
    precondition_failed(conn, state)
  end

  @spec if_modified_since_exists(conn, rest_state) :: conn
  defp if_modified_since_exists(conn, state) do
    case parse_date_header(conn, "if-modified-since") do
      [] ->
        method(conn, state)
      if_modified_since ->
        if_modified_since_now(conn, state, if_modified_since)
    end
  end

  @spec if_modified_since_now(conn, state, :calendar.time) :: conn
  defp if_modified_since_now(conn, state, if_modified_since) do
    universaltime =
      case Application.get_env(:plug_rest, :current_time_fun) do
        nil -> :erlang.universaltime
        fun -> fun.()
      end
    case if_modified_since > universaltime do
      true ->
        method(conn, state)
      false ->
        if_modified_since(conn, state, if_modified_since)
    end
  end

  defp if_modified_since(conn, state, if_modified_since) do
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
  end

  @spec not_modified(conn, rest_state) :: conn
  defp not_modified(conn, state) do
    conn2 = delete_resp_header(conn, "content-type")
    case set_resp_etag(conn2, state) do
      {conn3, state2} ->
        case set_resp_expires(conn3, state2) do
        {req4, state3} ->
          respond(req4, state3, 304)
        end
    end
  end

  @spec precondition_failed(conn, rest_state) :: conn
  defp precondition_failed(conn, state) do
    respond(conn, state, 412)
  end

  @spec is_put_to_missing_resource(conn, rest_state) :: conn
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

  @spec previously_existed(conn, rest_state) :: conn
  defp previously_existed(conn, state) do
    expect(conn, state, :previously_existed, false,
      fn r, s -> is_post_to_missing_resource(r, s, 404) end,
      fn r, s -> moved_permanently(r, s, &moved_temporarily/2) end)
  end

  @spec moved_temporarily(conn, rest_state) :: conn
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
    expect(conn, state, :allow_missing_post, false, on_false, &accept_resource/2)
  end

  @spec method(conn, rest_state) :: conn
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

  @spec delete_resource(conn, rest_state) :: conn
  defp delete_resource(conn, state) do
    expect(conn, state, :delete_resource, false, 500, &delete_completed/2)
  end

  @spec delete_completed(conn, rest_state) :: conn
  defp delete_completed(conn, state) do
    expect(conn, state, :delete_completed, true, &has_resp_body/2, 202)
  end

  @spec is_conflict(conn, rest_state) :: conn
  defp is_conflict(conn, state) do
    expect(conn, state, :is_conflict, false, &accept_resource/2, 409)
  end

  @spec accept_resource(conn, rest_state) :: conn
  defp accept_resource(conn, state) do
    case call(conn, state, :content_types_accepted) do
      :no_call ->
        respond(conn, state, 415)
      {:stop, conn2, handler_state} ->
        terminate(conn2, %{state | handler_state: handler_state})
      {c_ta, conn2, handler_state} ->
        c_ta2 = for(p <- c_ta, into: [], do: normalize_content_types(p))
        state2 = %{state | handler_state: handler_state}
          case parse_media_type_header(conn2, "content-type") do
            :error ->
              respond(conn2, state2, 415)
            content_type ->
              choose_content_type(conn2, state2, content_type, c_ta2)
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
      :no_call ->
        raise UndefinedFunctionError, module: state.handler, function: fun,
          arity: 2
    end
  end

  @spec maybe_created(conn, rest_state) :: conn
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

  @spec has_resp_body(conn, rest_state) :: conn
  defp has_resp_body(conn, state) do
    case get_rest_body(conn) do
      nil ->
        respond(conn, state, 204)
      _ ->
        multiple_choices(conn, state)
    end
  end

  @spec set_resp_body_etag(conn, rest_state) :: conn
  defp set_resp_body_etag(conn, state) do
    case set_resp_etag(conn, state) do
      {conn2, state2} ->
        set_resp_body_last_modified(conn2, state2)
    end
  end

  @spec set_resp_body_last_modified(conn, rest_state) :: conn
  defp set_resp_body_last_modified(conn, state) do
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
  end

  @spec set_resp_body_expires(conn, rest_state) :: conn
  defp set_resp_body_expires(conn, state) do
    case set_resp_expires(conn, state) do
      {conn2, state2} ->
        set_resp_body(conn2, state2)
    end
  end

  @spec set_resp_body(conn, rest_state) :: conn
  defp set_resp_body(conn, %{content_type_a: {_, callback}} = state) do
    case call(conn, state, callback) do
      {:stop, conn2, handler_state2} ->
        terminate(conn2, %{state | handler_state: handler_state2})
      {body, conn2, handler_state2} ->
        state2 = %{state | handler_state: handler_state2, resp_body: body}
        multiple_choices(conn2, state2)
      :no_call ->
        raise UndefinedFunctionError, module: state.handler, function: callback,
          arity: 2
    end
  end

  @spec multiple_choices(conn, rest_state) :: conn
  defp multiple_choices(conn, state) do
    expect(conn, state, :multiple_choices, false, 200, 300)
  end

  @spec set_resp_etag(conn, rest_state) :: {conn, rest_state}
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

  @spec set_resp_expires(conn, rest_state) :: {conn, rest_state}
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

  @spec generate_etag(conn, rest_state) :: {nil | {:weak | :strong, binary()}, conn, rest_state}
  defp generate_etag(conn, %{etag: :no_call} = state) do
    {nil, conn, state}
  end

  defp generate_etag(conn, %{etag: nil} = state) do
    case unsafe_call(conn, state, :generate_etag) do
      :no_call ->
        {nil, conn, %{state | etag: :no_call}}
      {etag, conn2, handler_state} when is_binary(etag) ->
        case :cowboy_http.entity_tag_match(etag) do
          {:error, :badarg} ->
            raise PlugRest.RuntimeError,
              message: "Invalid ETag #{inspect etag} (#{inspect state.handler})"
          tag_match ->
            {etag2} = List.to_tuple(tag_match)
            {etag2, conn2, %{state | handler_state: handler_state, etag: etag2}}
        end
      {etag, conn2, handler_state} ->
        {etag, conn2, %{state | handler_state: handler_state, etag: etag}}
    end
  end

  defp generate_etag(conn, %{etag: etag} = state) do
    {etag, conn, state}
  end

  @spec last_modified(conn, rest_state) :: {nil | :calendar.datetime(), conn, rest_state}
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

  @spec expires(conn, rest_state) :: {nil | :calendar.datetime() | binary, conn, rest_state}
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

  defp call(conn, %{handler: handler, handler_state: handler_state}= _state, callback) do
    case function_exported?(handler, callback, 2) do
      true ->
        apply(handler, callback, [conn, handler_state])
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

  # Do nothing if the resource has already sent a response
  defp terminate(%{state: :sent} = conn, _state) do
    conn
  end

  defp terminate(%{state: :chunked} = conn, _state) do
    conn
  end

  # Send the response if it has already been set
  defp terminate(%{state: :set} = conn, _state) do
    conn |> send_resp()
  end

  # If the resource has stopped without a status, send 204 No Content
  defp terminate(%{status: nil} = conn, _state) do
    conn |> send_resp(204, "")
  end

  # Send a response based on state.resp_body or conn.private.plug_rest_body
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
    # If the resource has set the response body manually with
    # `put_rest_body/2`, then use it. Otherwise, use the resource
    # state.
    resp_body =
      case get_rest_body(conn) do
        nil -> state.resp_body
        body -> body
      end

    conn |> send_resp(conn.status, resp_body)
  end

  ## Private connection.

  @doc """
  Manually sets the REST response body in the connection

  """
  @spec put_rest_body(conn, binary()) :: conn
  def put_rest_body(conn, resp_body) do
    put_private(conn, :plug_rest_body, resp_body)
  end

  @doc """
  Returns the REST response body if it has been set

  """
  @spec get_rest_body(conn) :: binary() | nil
  def get_rest_body(conn) do
    Map.get(conn.private, :plug_rest_body)
  end

  @doc false
  @spec get_media_type(conn) :: media_type | nil
  def get_media_type(conn) do
    Map.get(conn.private, :plug_rest_format)
  end

  @doc false
  @spec put_media_type(conn, media_type) :: conn
  def put_media_type(conn, media_type) do
    put_private(conn, :plug_rest_format, media_type)
  end
end
