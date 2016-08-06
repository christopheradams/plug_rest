defmodule PlugRest.State do
  @moduledoc false

  @type etag             :: binary | {:weak | :strong, binary}
  @type handler          :: atom
  @type media_type       :: {binary, binary, %{binary => binary} | :*}
  @type content_handler  :: {media_type, handler}

  @typep method          :: binary
  @typep handler_state   :: any
  @typep allowed_methods :: [binary]
  @typep language        :: binary
  @typep charset         :: binary
  @typep exists          :: boolean
  @typep last_modified   :: :calendar.datetime
  @typep expires         :: :calendar.datetime | binary
  @typep resp_body       :: binary | {:chunked, Enum.t} | {:file, String.t}

  @type t :: %__MODULE__{
              method:          method | nil,
              handler:         handler | nil,
              handler_state:   handler_state,
              allowed_methods: allowed_methods | nil,
              content_types_p: [content_handler],
              content_type_a:  content_handler | nil,
              languages_p:     [language],
              language_a:      language | nil,
              charsets_p:      [charset],
              charset_a:       charset | nil,
              exists:          exists,
              etag:            etag | nil,
              last_modified:   last_modified | :no_call | nil,
              expires:         expires | :no_call | nil,
              resp_body:       resp_body | nil
  }

  defstruct method:          nil,
            handler:         nil,
            handler_state:   nil,
            allowed_methods: nil,
            content_types_p: [],
            content_type_a:  nil,
            languages_p:     [],
            language_a:      nil,
            charsets_p:      [],
            charset_a:       nil,
            exists:          false,
            etag:            nil,
            last_modified:   nil,
            expires:         nil,
            resp_body:       nil
end
