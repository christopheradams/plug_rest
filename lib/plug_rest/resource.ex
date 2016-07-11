defmodule PlugRest.Resource do
  import Plug.Conn

  def upgrade(conn, _handler, _opts \\ []) do
    conn |> put_resp_content_type("text/html") |> send_resp(200, "Plug REST")
  end

  @callback test(conn, state) :: {[binary()], conn, state}
            when conn: %Plug.Conn{}, state: any()
  @optional_callbacks [test: 2]
end
