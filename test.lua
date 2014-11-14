local tuple = require "tuple"

local aux = {}
for i=1,10 do aux[tuple(i,i)] = i end
print(tuple.stats())
collectgarbage("collect")
print(tuple.stats())
local aux = nil
collectgarbage("collect")
print(tuple.stats())
collectgarbage("collect")
print(tuple.stats())
