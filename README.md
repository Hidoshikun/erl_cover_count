# erl_cover_count

-----

统计Erlang代码覆盖率的小模块

首先确保项目拥有如下结构，并且添加单元测试：

```erlang
project/
   └ ebin/
	  └ xxx.beam
   └ src/
	  └ cover_count.erl
```

`src/`用于存放源代码`.erl`文件，`ebin/`存放编译后的`.beam`文件

对于每一个`src/`目录下的模块，需要添加`test_module()`函数并导出，作为单元测试的内容。下面是一个`test_module()`的示例：

```erlang
test_module() ->
    %% 测试背包add方法
    ok = add(?MAKE_ITEM(2001, 1, 0), ?SOURCE_GM),
    %% 测试背包上限
    ok = add(?MAKE_ITEM(5001, ?PACKAGE_VOLUME_BAG, 0), ?SOURCE_GM),
    ?assertCatch({error, full_package}, add(?MAKE_ITEM(2011, 1, 0), ?SOURCE_GM, ?FALSE)),
    %% 测试背包del方法
    ?assertCatch({error, not_enough}, del_by_tid(9001, 1, ?SOURCE_GM)),
```

跑完一次test_module()后运行代码覆盖率统计，可获得代码覆盖率测试情况。

```erlang
(node@127.0.0.1)1> cover_count:calc_all_cover_rate().
|-------------------------------------------|
|              Code Cover Rate              | 
|-------------------------------------------|
|module name                    | cover rate|
|-------------------------------------------|
|module_a			           | 74%       |
|-------------------------------------------|
|module_b			           | 74%       |
|-------------------------------------------|
|module_c			           | 74%       |
|-------------------------------------------|

```

原理是在代码执行前和执行后调用Erlang中的`cover`模块方法，生成含有代码执行覆盖信息的`.COVER.out`文件，统计文件中执行次数大于0的代码行数占总代码行数的比例。