%%%-------------------------------------------------------------------
%%% @author Hiroe Shin <shin@mac-hiroe-orz-17.local>
%%% @copyright (C) 2011, Hiroe Shin
%%% @doc
%%%
%%% @end
%%% Created :  9 Oct 2011 by Hiroe Shin <shin@mac-hiroe-orz-17.local>
%%%-------------------------------------------------------------------
-module(eredis_pool).

%% Include
-include_lib("eunit/include/eunit.hrl").
-include_lib("eredis/include/eredis.hrl").

%% Default timeout for calls to the client gen_server
%% Specified in http://www.erlang.org/doc/man/gen_server.html#call-3
-define(TIMEOUT, 5000).
-define(POOL_TIMEOUT, 5000).

%% API
-export([start/0, stop/0]).
-export([create_pool/2, create_pool/3, create_pool/4, create_pool/5,
         create_pool/6, create_pool/7, create_pool/8]).
-export([delete_pool/1]).
-export([q/2, q/3, q/4]).
-export([qp/2, qp/3, qp/4]).
-export([transaction/2, transaction/3, transaction/4]).

%%%===================================================================
%%% API functions
%%%===================================================================

start() ->
    application:start(?MODULE).

stop() ->
    application:stop(?MODULE).

%% ===================================================================
%% @doc create new pool.
%% @end
%% ===================================================================
-spec(create_pool(PoolName::atom(), Size::integer()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size) ->
    eredis_pool_sup:create_pool(PoolName, {Size, 10}, []).

-spec(create_pool(PoolName::atom(), Size::integer(),
                  MaxOverflow::integer()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size, MaxOverflow) ->
    eredis_pool_sup:create_pool(PoolName, {Size, MaxOverflow}, []).

-spec(create_pool(PoolName::atom(), Size::integer(),
                  MaxOverflow::integer(), Host::string()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size, MaxOverflow, Host) ->
    eredis_pool_sup:create_pool(PoolName, {Size, MaxOverflow}, [{host, Host}]).

-spec(create_pool(PoolName::atom(), Size::integer(),
                  MaxOverflow::integer(), Host::string(),
                  Port::integer()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size, MaxOverflow, Host, Port) ->
    eredis_pool_sup:create_pool(PoolName, {Size, MaxOverflow}, [{host, Host}, {port, Port}]).

-spec(create_pool(PoolName::atom(), Size::integer(),
                  MaxOverflow::integer(), Host::string(),
                  Port::integer(), Database::string()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size, MaxOverflow, Host, Port, Database) ->
    eredis_pool_sup:create_pool(PoolName, {Size, MaxOverflow}, [{host, Host}, {port, Port},
                                                                {database, Database}]).

-spec(create_pool(PoolName::atom(), Size::integer(),
                  MaxOverflow::integer(), Host::string(),
                  Port::integer(), Database::string(),
                  Password::string()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size, MaxOverflow, Host, Port, Database, Password) ->
    eredis_pool_sup:create_pool(PoolName, {Size, MaxOverflow}, [{host, Host}, {port, Port},
                                                                {database, Database},
                                                                {password, Password}]).

-spec(create_pool(PoolName::atom(), Size::integer(),
                  MaxOverflow::integer(), Host::string(),
                  Port::integer(), Database::string(),
                  Password::string(), ReconnectSleep::integer()) ->
             {ok, pid()} | {error,{already_started, pid()}}).
create_pool(PoolName, Size, MaxOverflow, Host, Port, Database, Password, ReconnectSleep) ->
    eredis_pool_sup:create_pool(PoolName, {Size, MaxOverflow}, [{host, Host}, {port, Port},
                                                                {database, Database},
                                                                {password, Password},
                                                                {reconnect_sleep, ReconnectSleep}]).


%% ===================================================================
%% @doc delet pool and disconnected to Redis.
%% @end
%% ===================================================================
-spec(delete_pool(PoolName::atom()) -> ok | {error,not_found}).
delete_pool(PoolName) ->
    eredis_pool_sup:delete_pool(PoolName).

%%--------------------------------------------------------------------
%% @doc
%% Executes the given command in the specified connection. The
%% command must be a valid Redis command and may contain arbitrary
%% data which will be converted to binaries. The returned values will
%% always be binaries.
%% @end
%%--------------------------------------------------------------------
-spec q(PoolName::atom(), Command::iolist()) ->
               {ok, binary() | [binary()]} | {error, Reason::binary()}.
q(PoolName, Command) ->
    q(PoolName, Command, ?TIMEOUT).

-spec q(PoolName::atom(), Command::iolist(), Timeout::integer()) ->
               {ok, binary() | [binary()]} | {error, Reason::binary()}.
q(PoolName, Command, Timeout) ->
    q(PoolName, Command, Timeout, ?POOL_TIMEOUT).

-spec q(PoolName::atom(), Command::iolist(),
        Timeout::integer(), PoolTimeout::integer()) ->
               {ok, binary() | [binary()]} | {error, Reason::binary()}.
q(PoolName, Command, Timeout, PoolTimeout) ->
    poolboy:transaction(PoolName, fun(Worker) ->
                                          eredis:q(Worker, Command, Timeout)
                                  end, PoolTimeout).

-spec qp(PoolName::atom(), Pipeline::pipeline()) ->
                {ok, binary() | [binary()]} | {error, Reason::binary()}.
qp(PoolName, Pipeline) ->
    qp(PoolName, Pipeline, ?TIMEOUT).

-spec qp(PoolName::atom(), Pipeline::pipeline(), Timeout::integer()) ->
                {ok, binary() | [binary()]} | {error, Reason::binary()}.
qp(PoolName, Pipeline, Timeout) ->
    qp(PoolName, Pipeline, Timeout, ?POOL_TIMEOUT).

-spec qp(PoolName::atom(), Pipeline::pipeline(),
         Timeout::integer(), PoolTimeout::integer()) ->
                {ok, binary() | [binary()]} | {error, Reason::binary()}.
qp(PoolName, Pipeline, Timeout, PoolTimeout) ->
    poolboy:transaction(PoolName, fun(Worker) ->
                                          eredis:qp(Worker, Pipeline, Timeout)
                                  end, PoolTimeout).

-spec transaction(PoolName::atom(), Fun::fun()) ->
                         {ok, [binary()]} | {error, Reason::binary()}.
transaction(PoolName, Fun) when is_function(Fun) ->
    transaction(PoolName, Fun, ?TIMEOUT).

-spec transaction(PoolName::atom(), Fun::fun(), Timeout::integer()) ->
                         {ok, [binary()]} | {error, Reason::binary()}.
transaction(PoolName, Fun, Timeout) when is_function(Fun) ->
    transaction(PoolName, Fun, Timeout, ?POOL_TIMEOUT).

-spec transaction(PoolName::atom(), Fun::fun(),
                  Timeout::integer(), PoolTimeout::integer()) ->
                         {ok, [binary()]} | {error, Reason::binary()}.
transaction(PoolName, Fun, Timeout, PoolTimeout) when is_function(Fun) ->
    F = fun(C) ->
                try
                    {ok, <<"OK">>} = eredis:q(C, ["MULTI"], Timeout),
                    Fun(C),
                    eredis:q(C, ["EXEC"], Timeout)
                catch
                    error:{badmatch,{error,no_connection}} ->
                        io:format("Unable to connect to Redis"),
                        {error, no_connection};
                    Klass:Reason ->
                        {ok, <<"OK">>} = eredis:q(C, ["DISCARD"], Timeout),
                        io:format("Error in redis transaction. ~p:~p",
                                  [Klass, Reason]),
                        {Klass, Reason}
                end
        end,
    poolboy:transaction(PoolName, F, PoolTimeout).
