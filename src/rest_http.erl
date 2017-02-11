%% Copyright (c) 2011-2014, Loïc Hoguin <essen@ninenines.eu>
%% Copyright (c) 2011, Anthony Ramine <nox@dev-extend.eu>
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

%% Deprecated HTTP parsing API.
%% Copied from cowboy_http.
-module(rest_http).

%% Parsing.
-export([list/2]).
-export([nonempty_list/2]).
-export([entity_tag_match/1]).
-export([whitespace/2]).
-export([quoted_string/2]).

%% Parsing.

-spec nonempty_list(binary(), fun()) -> [any(), ...] | {error, badarg}.
nonempty_list(Data, Fun) ->
	case list(Data, Fun, []) of
		{error, badarg} -> {error, badarg};
		[] -> {error, badarg};
		L -> lists:reverse(L)
	end.

-spec list(binary(), fun()) -> list() | {error, badarg}.
list(Data, Fun) ->
	case list(Data, Fun, []) of
		{error, badarg} -> {error, badarg};
		L -> lists:reverse(L)
	end.

-spec list(binary(), fun(), [binary()]) -> [any()] | {error, badarg}.
%% From the RFC:
%% <blockquote>Wherever this construct is used, null elements are allowed,
%% but do not contribute to the count of elements present.
%% That is, "(element), , (element) " is permitted, but counts
%% as only two elements. Therefore, where at least one element is required,
%% at least one non-null element MUST be present.</blockquote>
list(Data, Fun, Acc) ->
	whitespace(Data,
		fun (<<>>) -> Acc;
			(<< $,, Rest/binary >>) -> list(Rest, Fun, Acc);
			(Rest) -> Fun(Rest,
				fun (D, I) -> whitespace(D,
						fun (<<>>) -> [I|Acc];
							(<< $,, R/binary >>) -> list(R, Fun, [I|Acc]);
							(_Any) -> {error, badarg}
						end)
				end)
		end).

-spec entity_tag_match(binary()) -> any().
entity_tag_match(<< $*, Rest/binary >>) ->
	whitespace(Rest,
		fun (<<>>) -> '*';
			(_Any) -> {error, badarg}
		end);
entity_tag_match(Data) ->
	nonempty_list(Data, fun entity_tag/2).

-spec entity_tag(binary(), fun()) -> any().
entity_tag(<< "W/", Rest/binary >>, Fun) ->
	opaque_tag(Rest, Fun, weak);
entity_tag(Data, Fun) ->
	opaque_tag(Data, Fun, strong).

-spec opaque_tag(binary(), fun(), weak | strong) -> any().
opaque_tag(Data, Fun, Strength) ->
	quoted_string(Data,
		fun (_Rest, <<>>) -> {error, badarg};
			(Rest, OpaqueTag) -> Fun(Rest, {Strength, OpaqueTag})
		end).

-spec whitespace(binary(), fun()) -> any().
whitespace(<< C, Rest/binary >>, Fun)
		when C =:= $\s; C =:= $\t ->
	whitespace(Rest, Fun);
whitespace(Data, Fun) ->
	Fun(Data).

-spec quoted_string(binary(), fun()) -> any().
quoted_string(<< $", Rest/binary >>, Fun) ->
	quoted_string(Rest, Fun, <<>>);
quoted_string(_, _Fun) ->
    {error, badarg}.

-spec quoted_string(binary(), fun(), binary()) -> any().
quoted_string(<<>>, _Fun, _Acc) ->
	{error, badarg};
quoted_string(<< $", Rest/binary >>, Fun, Acc) ->
	Fun(Rest, Acc);
quoted_string(<< $\\, C, Rest/binary >>, Fun, Acc) ->
	quoted_string(Rest, Fun, << Acc/binary, C >>);
quoted_string(<< C, Rest/binary >>, Fun, Acc) ->
	quoted_string(Rest, Fun, << Acc/binary, C >>).

%% Tests.

-ifdef(TEST).
entity_tag_match_test_() ->
	Tests = [
		{<<"\"xyzzy\"">>, [{strong, <<"xyzzy">>}]},
		{<<"\"xyzzy\", W/\"r2d2xxxx\", \"c3piozzzz\"">>,
			[{strong, <<"xyzzy">>},
			 {weak, <<"r2d2xxxx">>},
			 {strong, <<"c3piozzzz">>}]},
		{<<"*">>, '*'}
	],
	[{V, fun() -> R = entity_tag_match(V) end} || {V, R} <- Tests].
-endif.
