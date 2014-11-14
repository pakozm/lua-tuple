Lua-Tuple
=========

In-mutable and interned tuple table for Lua. Tuples can be sorted lexicographically and concatenated by default.

Installation
------------

Copy the file `tuple.lua` to your LUA_PATH.

Use
---

Lua-Tuple allows to declare in-mutable and interned tuples in Lua.
Creation of tuples is a time consuming operation due to internalization,
however, they can be used as keys of Lua tables thanks to that. Tuples
can store numbers, strings and tables, nevertheless, table values will
be converted into tuples recursively. Tables can't have reference loops,
otherwise the tuple constructor will crash in a stack overflow.

```Lua
> tuple = require "tuple"
> t1 = tuple(3,2,1)
> print(t1)
tuple( 3, 2, 1 )
> -- tuple from a table
> t2 = tuple{3,2,1}
> print(t1 == t2)
true
> -- tuples with one element are unpacked by default
> print( tuple(3) )
3
> -- but it can be forced by using table constructor
> print( tuple{3} )
tuple{ 3 }
> t3 = tuple(t1,{4,5,t1})
> print(t3)
tuple{ tuple{ 3, 2, 1 }, tuple{ 4, 5, tuple{ 3, 2, 1 } } }
> aux = { [t1] = "t1", [t3] = "t3" }
> print(aux)
table: 0x26fdc70
> print(aux[t1])
t1
> print(aux[t3])
t3
> loop_table = {4,5}
> table.insert(loop_table, loop_table)
> fail = tuple(loop_table)
./tuple.lua:116: stack overflow
stack traceback:
	./tuple.lua:117: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	...
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	./tuple.lua:118: in function 'tuple_constructor'
	./tuple.lua:134: in function 'tuple'
	stdin:1: in main chunk
	[C]: in ?
```
