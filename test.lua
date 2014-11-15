local tuple = require "tuple"
tuple.utest()
local t = tuple(1,4,2)
-- check unpack is working out of tuple module
local a,b,c = table.unpack(t)
assert(a == 1 and b == 4 and c == 2)
