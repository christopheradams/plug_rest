defmodule <%= module %> do
  use <%= resources_use %>

  def allowed_methods(conn, state) do
    {["GET,", "HEAD", "OPTIONS"], conn, state}
  end

  def allow_missing_post(conn, state) do
    {true, conn, state}
  end

  def charsets_provided(conn, state) do
    {["utf-8"], conn, state}
  end

  def content_types_accepted(conn, state) do
    {[{"application/json", :from_json}], conn, state}
  end

  def from_json(conn, state) do
    {true, conn, state}
  end

  def content_types_provided(conn, state) do
    {[{"application/json", :to_json}], conn, state}
  end

  def to_json(conn, state) do
    {"{}", conn, state}
  end

  def delete_completed(conn, state) do
    {true, conn, state}
  end

  def delete_resource(conn, state) do
    {false, conn, state}
  end

  def expires(conn, state) do
    {nil, conn, state}
  end

  def forbidden(conn, state) do
    {false, conn, state}
  end

  def generate_etag(conn, state) do
    {nil, conn, state}
  end

  def is_authorized(conn, state) do
    {true, conn, state}
  end

  def is_conflict(conn, state) do
    {false, conn, state}
  end

  def known_methods(conn, state) do
    {["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"], conn, state}
  end

  def languages_provided(conn, state) do
    {["en"], conn, state}
  end

  def last_modified(conn, state) do
    {nil, conn, state}
  end

  def malformed_request(conn, state) do
    {false, conn, state}
  end

  def moved_permanently(conn, state) do
    {false, conn, state}
  end

  def moved_temporarily(conn, state) do
    {false, conn, state}
  end

  def multiple_choices(conn, state) do
    {false, conn, state}
  end

  def options(conn, state) do
    {:ok, conn, state}
  end

  def previously_existed(conn, state) do
    {false, conn, state}
  end

  def resource_exists(conn, state) do
    {true, conn, state}
  end

  def service_available(conn, state) do
    {true, conn, state}
  end

  def uri_too_long(conn, state) do
    {false, conn, state}
  end

  def valid_content_headers(conn, state) do
    {true, conn, state}
  end

  def valid_entity_length(conn, state) do
    {true, conn, state}
  end

  def variances(conn, state) do
    {[], conn, state}
  end
end
