defmodule PlugRest.State do

  defstruct env: nil,
    method: nil,
    handler: nil,
    handler_state: nil,
    allowed_methods: nil,
    content_types_p: [],
    content_type_a: nil,
    languages_p: [],
    language_a: nil,
    charsets_p: [],
    charset_a: nil,
    exists: false,
    etag: :undefined,
    last_modified: :undefined,
    expires: :undefined,
    resp_body: nil
end
