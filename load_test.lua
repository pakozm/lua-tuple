local tuple = require "tuple"
print(table.unpack(tuple(2,3,4,5)))
collectgarbage("collect")
print( collectgarbage("count") )
local aux={} for i=1,1000000 do aux[i]=tuple(i,i,i,i,i,i,i) end
collectgarbage("collect")
print( collectgarbage("count") )
print(tuple.stats())
aux = nil
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
print( collectgarbage("count") )
print(tuple.stats())

local aux={} for i=1,1000000 do aux[i]=tuple(i,i,i,i,i,i) end
collectgarbage("collect")
print( collectgarbage("count") )
print(tuple.stats())
aux = nil
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
print( collectgarbage("count") )
print(tuple.stats())

--[[
2	3	4	5
46.2861328125	293
505768.26269531	269
1000000	645167	0.95367431640625	1000000
57389.715820312	733
0	1	0	0
505733.76269531	781
1000000	644600	0.95367431640625	1000000
57389.747070312	765
0	1	0	0
]]
