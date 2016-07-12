defmodule PlugRest.State do

  defstruct env: nil,
    method: :undefined,
    handler: nil,
    handler_state: nil,
    allowed_methods: nil,
    content_types_p: [],
    content_type_a: :undefined,
    languages_p: [],
    language_a: :undefined,
    charsets_p: [],
    charset_a: :undefined,
    exists: false,
    etag: :undefined,
    last_modified: nil,
    expires: nil,
    body: []
end
