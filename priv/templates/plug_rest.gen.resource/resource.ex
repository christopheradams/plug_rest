defmodule <%= module %> do
  @moduledoc """
  This is the documentation for the <%= module %> module.

  See [PlugRest docs](https://hexdocs.pm/plug_rest/PlugRest.Resource.html)
  for more information on the REST callbacks.
  """

  use <%= resources_use %>

  ## Customized callbacks.

  # Returns the list of allowed methods
  def allowed_methods(conn, state) do
    {["GET", "HEAD", "OPTIONS", "POST"], conn, state}
  end

  ### Content Negotiation.

  # Returns the list of content-types the resource accepts
  #
  # This function will be called for POST, PUT, and PATCH requests.
  #
  # Each content-type ("application/json") is paired with a function
  # (`:from_json`) that will handle it.
  #
  # For HTML form submissions you can add:
  #
  #     {"mixed/multipart", :from_multipart}
  def content_types_accepted(conn, state) do
    {[{"application/json", :from_json}], conn, state}
  end

  @doc """
  Accepts an application/json representation of the resource
  """
  # The return value can be `true` (content accepted), `{true, URL}`
  # (redirect to new resource), or `false` (error).
  def from_json(conn, state) do
    {true, conn, state}
  end

  # Returns the list of content-types the resource provides
  #
  # Each content-type ("application/json") is paired with a function
  # (`:to_json`) that will handle it.
  #
  # For HTML you can add:
  #
  #     {"text/html", :to_html}
  def content_types_provided(conn, state) do
    {[{"application/json", :to_json}], conn, state}
  end

  @doc """
  Returns an application/json representation of the resource
  """
  def to_json(conn, state) do
    {"{}", conn, state}
  end

  ## Default callbacks. You may customize or remove.

  # Returns whether the service is available
  #
  # Use this to confirm all backend systems are up.
  def service_available(conn, state) do
    {true, conn, state}
  end

  # Returns the list of known methods
  def known_methods(conn, state) do
    {["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"], conn, state}
  end

  # Returns whether the requested URI is too long
  def uri_too_long(conn, state) do
    {false, conn, state}
  end

  # Returns whether the request is malformed
  def malformed_request(conn, state) do
    {false, conn, state}
  end

  # Returns whether the user is authorized to perform the action
  #
  # When returning `false` you can set the value of the WWW-Authenticate
  # header:
  #
  #     {{false, "Basic realm=\"MyApp\""}, conn, state}
  def is_authorized(conn, state) do
    {true, conn, state}
  end

  # Returns whether access to the resource is forbidden
  def forbidden(conn, state) do
    {false, conn, state}
  end

  # Returns whether the content-* headers are valid
  def valid_content_headers(conn, state) do
    {true, conn, state}
  end

  # Returns whether the request body length is within acceptable boundaries
  def valid_entity_length(conn, state) do
    {true, conn, state}
  end

  # Handles a request for information
  #
  # If undefined, this callback will respond to an OPTIONS request
  # with the list of allowed methods.
  #
  # To customize the response, manipulate the `conn` as needed
  # and reply with an `:ok` value.
  def options(conn, state) do
    allow = "GET, HEAD, OPTIONS, POST"
    conn = conn |> put_resp_header("allow", allow)
    {:ok, conn, state}
  end

  # Returns the list of languages the resource provides
  def languages_provided(conn, state) do
    {["en"], conn, state}
  end

  # Returns the list of charsets the resource provides
  def charsets_provided(conn, state) do
    {["utf-8"], conn, state}
  end

  # Returns whether the resource exists
  #
  # Returning `false` will send a `404 Not Found` response, unless the
  # method is POST and `allow_missing_post` is true.
  def resource_exists(conn, state) do
    {true, conn, state}
  end

  # Returns the entity tag of the resource
  #
  # This value will be sent as the value of the etag header.
  #
  # Examples
  #
  #     # ETag: W/"etag-header-value"
  #     def generate_etag(conn, state) do
  #       {{:weak, "etag-header-value"}, conn, state}
  #     end
  #
  #     # ETag: "etag-header-value"
  #     def generate_etag(conn, state) do
  #       {{:strong, "etag-header-value"}, conn, state}
  #     end
  #
  #     # ETag: "etag-header-value"
  #     def generate_etag(conn, state) do
  #       {"\"etag-header-value\""}, conn, state}
  #     end
  def generate_etag(conn, state) do
    {nil, conn, state}
  end

  # Returns the date of expiration of the resource
  #
  # This date will be sent as the value of the expires header. The date
  # can be specified as a `datetime()` tuple or a string.
  #
  # Examples
  #
  #     def expires(conn, state) do
  #       {{{2012, 9, 21}, {22, 36, 14}}, conn, state}
  #     end
  def expires(conn, state) do
    {nil, conn, state}
  end

  # Returns the date of last modification of the resource
  #
  # Returning a `datetime()` tuple will set the last-modified header and
  # be used for comparison in conditional if-modified-since and
  # if-unmodified-since requests.
  #
  # Examples
  #
  #     def last_modified(conn, state) do
  #       {{{2012, 9, 21}, {22, 36, 14}}, conn, state}
  #     end
  def last_modified(conn, state) do
    {nil, conn, state}
  end

  # Returns whether the resource was permanently moved
  #
  # Returning `{true, URI}` will send a `301 Moved Permanently` response
  # with the URI in the Location header.
  def moved_permanently(conn, state) do
    {false, conn, state}
  end

  # Returns whether the resource existed previously
  #
  # Use this for a resource that should return `410 Gone`.
  def previously_existed(conn, state) do
    {false, conn, state}
  end

  # Returns whether the resource was temporarily moved
  #
  # Returning `{true, URI}` will send a `307 Temporary Redirect`
  # response with the URI in the Location header.
  def moved_temporarily(conn, state) do
    {false, conn, state}
  end

  # Returns whether POST is allowed when the resource doesn't exist
  #
  # This function will be called when `resource_exists` is `false` and
  # the request method is POST. Returning `true` means the missing
  # resource can process the enclosed representation, and the resource's
  # content accepted handler will be invoked.
  #
  # Returning `true` means POST should update an existing resource and
  # create one if it is missing.
  #
  # Returning `false` means POST to a missing resource will return `404
  # Not Found`.
  def allow_missing_post(conn, state) do
    {false, conn, state}
  end

  # Deletes the resource
  #
  # Delete the resource and return `true` unless there are any problems.
  def delete_resource(conn, state) do
    {false, conn, state}
  end

  # Returns whether the delete action has been completed
  #
  # Return `true` if the resource has been deleted or `false` if the
  # deletion needs more time to process.
  def delete_completed(conn, state) do
    {true, conn, state}
  end

  # Returns whether the PUT action results in a conflict
  #
  # Returning `true` will send a `409 Conflict` response.
  def is_conflict(conn, state) do
    {false, conn, state}
  end

  # Returns whether there are multiple representations of the resource
  #
  # See the documentation for more info.
  def multiple_choices(conn, state) do
    {false, conn, state}
  end

  # Return the list of headers that affect the representation of the resource
  #
  # See the documentation for more info.
  def variances(conn, state) do
    {[], conn, state}
  end
end
