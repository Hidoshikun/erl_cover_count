
%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2020, <>
%%% @doc
%%% 用于游戏项目的单元测试，输出代码覆盖率和测试未覆盖的代码
%%% 进行单元测试的模块需要先在模块内写好test_module()方法
%%% 本质是对cover模块方法的封装
%%% @end
%%% Created : 12. 八月 2020 16:30
%%%-------------------------------------------------------------------
-module(code_count).
-author("").

-include("logger.hrl").

-include("define/def_atom.hrl").

%% API
-export([
%%    code_count/0
    module_test/0
    , module_test/1
    , calc_all_cover_rate/0
    , calc_cover_rate/1
    , get_all_uncover_content/0
    , get_uncover_content/1
]).

-define(UNCOVER_CONTENT_FILE, "uncover_content_file.log").  % 测试覆盖内容输出文件
-define(MODULE_LIST, []).   % 写好单元测试的模块列表

%% ====================================================================
%% API functions
%% ====================================================================
%% @doc 统计项目行数，使用wc -l命令即可，就不新写函数了
% code_count() ->
%     {_, StartPwd} = file:get_cwd(),
%     FinalCount = calc_dir_loop(StartPwd),
%     ?WARNING_MSG("FinalCount ~p", [FinalCount]).
%     file:read_line()

%% @doc 进行模块单元测试，需要提前编写好单元测试内容
module_test() ->
    cover_start(),
    [Module:test_module() || Module <- ?MODULE_LIST],
    cover_stop(),
    ok.

module_test(Module0) ->
    Module = list_to_atom(Module0),
    cover_start(Module),
    Module:test_module(),
    cover_stop(Module),
    ok.

%% @doc 计算全部文件的代码覆盖率
calc_all_cover_rate() ->
    {_, FileList} = file:list_dir_all("ebin"),
    file:set_cwd("ebin"),
    FilterFun = fun(File) ->
        case re:run(File, "^.*\.(COVER.out)$") of
            {match, _} -> ?TRUE;
            _ -> ?FALSE
        end
                end,
    CoverFileList = [File || File <- FileList, FilterFun(File)],
    io:format("|~43.43c|~n", [$-]),
    io:format("|              Code Cover Rate              | ~n"),
    io:format("|~43.43c|~n", [$-]),
    io:format("|~-30." "s | ~-10." "s|~n", ["module name", "cover rate"]),
    CountFun = fun(F) ->
        io:format("|~43.43c|~n", [$-]),
        CoverRate = calc_cover_rate(F),
        io:format("|~-30." "s | ~-10" "s|~n",
            [string:substr(F, 1, length(F) - 10), integer_to_list(CoverRate) ++ "%"])
               end,
    [CountFun(F) || F <- CoverFileList],
    io:format("|~43.43c|~n", [$-]),
    file:set_cwd("..").

%% @doc 获取代码测试中所有未覆盖的内容
get_all_uncover_content() ->
    {_, FileList} = file:list_dir_all("ebin"),
    file:set_cwd("ebin"),
    FilterFun = fun(File) ->
        case re:run(File, "^.*\.(COVER.out)$") of
            {match, _} -> ?TRUE;
            _ -> ?FALSE
        end
                end,
    CoverFileList = [File || File <- FileList, FilterFun(File)],
    [get_uncover_content(F) || F <- CoverFileList],
    file:set_cwd("..").

%% @doc 获取代码覆盖测试中未覆盖的内容
get_uncover_content(Module) ->
    FileName = lists:concat([util:to_list(Module), ".COVER.out"]),
    Content = count_uncover_content_inner(FileName, util:to_binary("Uncover content in module: " ++ util:to_list(Module))),
    file:write_file(?UNCOVER_CONTENT_FILE, util:to_binary(Content)),
    ok.

%% @doc 计算代码覆盖率
calc_cover_rate(Module) ->
    FileName = lists:concat([util:to_list(Module), ".COVER.out"]),
    {CoverCount, NotCoverCount} = calc_file_cover_inner(FileName),
    round(CoverCount * 100 / (CoverCount + NotCoverCount)).

%% ====================================================================
%% Local functions
%% ====================================================================
%%calc_dir_loop(Pwd) ->
%%    calc_dir_loop(Pwd, 0).
%%calc_dir_loop(Pwd, Count) ->
%%    file:set_cwd(Pwd),
%%    {_, DirOrFileList} = file:list_dir_all(Pwd),
%%    Fun = fun(DirOrFile, {AccDirList, AccFileList}) ->
%%        case re:run(DirOrFile, "^(?!.*\.).*$") of
%%            {match, _} ->
%%                {[DirOrFile | AccDirList], AccFileList};
%%            _ ->
%%                case re:run(DirOrFile, "^.*\.(hrl|erl)$") of
%%                    {match, _} ->
%%                        {AccDirList, [DirOrFile | AccFileList]};
%%                    _ ->
%%                        {AccDirList, AccFileList}
%%                end
%%        end
%%          end,
%%    {DirList, ErlFileList} = lists:foldl(Fun, {[], []}, DirOrFileList),
%%    CodeLine = lists:sum([calc_file_line(File) || File <- ErlFileList]),
%%    Final = lists:foldl(fun calc_dir_loop/2, CodeLine + Count, DirList),
%%    file:set_cwd(".."),
%%    Final.
%%
%%calc_file_line(_) ->
%%    100.

%% @doc 代码覆盖测试
%% @param Module::Atom
cover_start(Module) ->
    _ = file:set_cwd("ebin"),
    cover:start(),
    case cover:compile_beam(Module) of
        {error, Reason} ->
            io:format("error ~p~n", [Reason]);
        _ ->
            skip
    end,
    _ = file:set_cwd("..").

%% @param Module::Atom
cover_stop(Module) ->
    cover_stop(Module, true).
cover_stop(Module, IsOpen) ->
    _ = file:set_cwd("ebin"),
    cover:analyse_to_file(),
    case IsOpen of
        true ->
            os:cmd("notepad " ++ atom_to_list(Module) ++ ".COVER.out");
        false ->
            skip
    end,
    cover:stop(),
    _ = file:set_cwd("..").

cover_start() ->
    _ = file:set_cwd("ebin"),
    cover:start(),
    case cover:compile_beam_directory() of
        {error, Reason} ->
            io:format("error ~p~n", [Reason]);
        _ ->
            skip
    end,
    _ = file:set_cwd("..").

cover_stop() ->
    _ = file:set_cwd("ebin"),
    cover:analyse(),
    cover:stop(),
    _ = file:set_cwd("..").

calc_file_cover_inner(File) ->
    {ok, Fd} = file:open(File, read),
    Result = count_cover_line_inner(Fd, 0, 0),
    file:close(Fd),
    Result.

count_uncover_content_inner(Fd, Content) ->
    case file:read_line(Fd) of
        eof ->
            file:close(Fd),
            Content;
        {ok, Line} ->
            case re:run(Line, "\\.\\.\\|") of
                {match, _} ->
                    case re:run(Line, " 0\\.\\.\\|") of
                        {match, _} ->
                            count_uncover_content_inner(Fd, Line ++ Content);
                        _ ->
                            count_uncover_content_inner(Fd, Content)
                    end;
                _ ->
                    count_uncover_content_inner(Fd, Content)
            end
    end.

count_cover_line_inner(Fd, CoveredCount, NotCoverCount) ->
    case file:read_line(Fd) of
        eof ->
            file:close(Fd),
            {CoveredCount, NotCoverCount};
        {ok, Line} ->
            case re:run(Line, "\\.\\.\\|") of
                {match, _} ->
                    case re:run(Line, " 0\\.\\.\\|") of
                        {match, _} ->
                            count_cover_line_inner(Fd, CoveredCount, NotCoverCount + 1);
                        _ ->
                            count_cover_line_inner(Fd, CoveredCount + 1, NotCoverCount)
                    end;
                _ ->
                    count_cover_line_inner(Fd, CoveredCount, NotCoverCount)
            end
    end.



