-module(ferl).

-export([ eval/4, start/0, start/1 ]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Publics 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% terminate evaluation
eval([], Data, [], Dictionary) ->
	{ Data, Dictionary };

%% Return to evaluation
eval([], Data, [ Fun | Rem ], Dictionary) ->
	eval(Fun, Data, Rem, Dictionary);

%% add two numbers on stack
eval([ "+" | Cont], [A,B|Data], Return, Dictionary) ->
	io:format("Pushing ~p + ~p~n", [ B, A ]),
	eval(Cont, [ B + A | Data ], Return, Dictionary);

%% subtract top of stack from next on stack
eval([ "-" | Cont], [A,B|Data], Return, Dictionary) ->
	io:format("Pushing ~p - ~p~n", [ B, A ]),
	eval(Cont, [ B - A | Data ], Return, Dictionary);

%% multiply two number on the stack
eval([ "*" | Cont], [A,B|Data], Return, Dictionary) ->
	io:format("Pushing ~p * ~p~n", [ B, A ]),
	eval(Cont, [ B * A | Data ], Return, Dictionary);

%% divide next on stack by top of stack
eval([ "/" | Cont], [A,B|Data], Return, Dictionary) ->
	io:format("Pushing ~p / ~p~n", [ B, A ]),
	eval(Cont, [ B / A | Data ], Return, Dictionary);

%% Print the top of the stack
eval([ "print" | Cont ], [ A | Data ], Return, Dictionary) ->
	io:format("~p~n", [ A ]),
	eval(Cont, Data, Return, Dictionary);

%% Duplicate top of the stack
eval([ "dup" | Cont ], [ A | Data ], Return, Dictionary) ->
	eval(Cont, [ A, A | Data ], Return, Dictionary);

%% Drop top of the stack
eval([ "drop" | Cont ], [ _A | Data ], Return, Dictionary) ->
	eval(Cont, Data, Return, Dictionary);

%% Dup next on stack
eval([ "over" | Cont ], [ A, B | Data ], Return, Dictionary) ->
	eval(Cont, [ B, A, B | Data ], Return, Dictionary);

%% Drop the next on stack
eval([ "nip" | Cont ], [ A, _B | Data ], Return, Dictionary) ->
	eval(Cont, [ A | Data ], Return, Dictionary);

%% Define a function
eval([ ":", Name | Cont ], Data, Return, Dictionary) ->
	io:format("Defining ~p~n", [ Name ]),
	{ Def, Rem } = until_semi(Cont,[]),
	eval(Rem, Data, Return, [ { Name, Def } | Dictionary ]);

%% Conditional Return
eval([ "?", True, False | Cont ], [ Flag | Data ], Return, Dictionary) ->
	if	%% flag is false, continue
		Flag =:= 0  -> 
			{ False, Fun } = proplists:lookup(False,Dictionary);
		true -> 
			{ True, Fun } = proplists:lookup(True,Dictionary)
	end,
	eval(Fun, Data, [ Cont | Return ], Dictionary);
		
%% Function call or Literal push
eval([ Op | Cont ],Data,Return,Dictionary) ->
	io:format("Pushing ~p~n", [ Op ]),
	case proplists:lookup(Op,Dictionary) of
		{ Op, Fun } ->
			io:format("Calling ~p ~n", [ Op ]),
			eval(Fun, Data, [ Cont | Return ], Dictionary);
		none -> 
			eval(Cont, [ Op | Data ], Return, Dictionary)
	end.

start(Pid) ->
	F = fun(F,Data,Dictionary) ->
		receive 
			Msg -> 
				{ Data2, Dictionary2 } = eval(Msg,Data,[],Dictionary),
				Pid ! { Data2 }
		end,
		F(F,Data2,Dictionary2)
	end,
	spawn(fun() -> F(F,[],[]) end).

start() ->
	start(self()).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Internals 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Snarfs the instruction stream until ; is encountered
%% returns { Definition, Remainder }
until_semi([], Acc) ->
	{ lists:reverse(Acc), [] };
until_semi([ ";" | Rest ], Acc) ->
	{ lists:reverse(Acc), Rest };
until_semi([ X | Rest ], Acc) ->
	until_semi(Rest, [ X | Acc ]).


