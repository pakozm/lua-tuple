--[[
  This file is part of Lua-Tuple (https://github.com/pakozm/lua-tuple)
  This file is part of Lua-MapReduce (https://github.com/pakozm/lua-mapreduce)
  
  Copyright 2014, Francisco Zamora-Martinez
  
  The Lua-MapReduce toolkit is free software; you can redistribute it and/or modify it
  under the terms of the GNU General Public License version 3 as
  published by the Free Software Foundation
  
  This library is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
  for more details.
  
  You should have received a copy of the GNU General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
]]

local tuple = {
  _VERSION = "0.1",
  _NAME = "tuple",
}

local MAX_BUCKET_HOLES_RATIO = 100
local NUM_BUCKETS = 2^20
local WEAK_MT = { __mode="v" }
local list_of_tuples = setmetatable({}, {}) -- WEAK_MT)

local function dump_number(n)
  return string.format("%c%c%c%c%c%c%c%c",
		       bit32.band(n,0xFF),
		       bit32.band(bit32.rshift(n,8),0x00000000000000FF),
		       bit32.band(bit32.rshift(n,16),0x00000000000000FF),
		       bit32.band(bit32.rshift(n,24),0x00000000000000FF),
		       bit32.band(bit32.rshift(n,32),0x00000000000000FF),
		       bit32.band(bit32.rshift(n,40),0x00000000000000FF),
		       bit32.band(bit32.rshift(n,48),0x00000000000000FF),
		       bit32.band(bit32.rshift(n,56),0x00000000000000FF))
end

local function compute_hash(t)
  local h = 0
  for i=1,#t do
    local v = t[i]
    local tt = type(v)
    if tt == "number" then v = dump_number(v)
    elseif tt == "table" then v = dump_number(compute_hash(v))
    elseif tt == "nil" then v = "nil"
    end
    assert(type(v) == "string",
	   "Needs an array with numbers, tables or strings")
    for j=1,#v do
      h = h + string.byte(string.sub(v,j,j))
      h = h + bit32.lshift(h,10)
      h = bit32.bxor(h,  bit32.rshift(h,6))
      h = bit32.band(h, 0x00000000FFFFFFFF)
    end
  end
  h = h + bit32.rshift(h,3)
  h = bit32.bxor(h, bit32.lshift(h,11))
  h = h + bit32.lshift(h,15)
  h = bit32.band(h, 0x00000000FFFFFFFF)
  return h
end

local tuple_instance_mt = {
  __metatable = false,
  __newindex = function(self) error("Unable to modify a tuple") end,
  __tostring = function(self)
    local result = {}
    for i=1,#self do
      local v = self[i]
      if type(v) == "string" then v = string.format("%q",v) end
      result[#result+1] = tostring(v)
    end
    return table.concat({"tuple(",table.concat(result, ", "),")"}, " ")
  end,
  __concat = function(self,other)
    local aux = {}
    for i=1,#self do aux[#aux+1] = self[i] end
    if type(other) == "table" then
      for i=1,#other do aux[#aux+1] = other[i] end
    else
      aux[#aux+1] = other
    end
    return tuple(aux)
  end,
}

local function proxy(tpl,n)
  setmetatable(tpl, tuple_instance_mt)
  return setmetatable({}, {
      __metatable = { "is_tuple", tpl , n },
      __index = tpl,
      __newindex = function(self) error("Tuples are in-mutable data") end,
      __len = function(self) return getmetatable(self)[3] end,
      -- __tostring = function(self) return tostring(getmetatable(self)[2]) end,
      __lt = function(self,other)
	local t = getmetatable(self)[2]
	if type(other) ~= "table" then return false
	elseif #t < #other then return true
	elseif #t > #other then return false
	elseif t == other then return false
	else
	  for i=1,#t do
	    if t[i] > other[i] then return false end
	  end
	  return true
	end
      end,
      __le = function(self,other)
	local t = getmetatable(self)[2]
	-- equality is comparing references (tuples are in-mutable and interned)
	if self == other then return true end
	return self < other
      end,
      __pairs = function(self) return pairs(getmetatable(self)[2]) end,
      __ipairs = function(self) return ipairs(getmetatable(self)[2]) end,
      __concat = function(self,other) return getmetatable(self)[2] .. other end,
      __mode = "v",
  })
end

local function tuple_constructor(t)
  local new_tuple = {}
  for i,v in pairs(t) do
    if i~="n" then
      assert(type(i) == "number" and i>0, "Needs integer keys > 0")
      if type(v) == "table" then
	new_tuple[i] = tuple(v)
      else
	new_tuple[i] = v
      end
    end
  end
  return proxy(new_tuple,#t)
end

local tuple_mt = {
  -- tuple constructor doesn't allow table loops
  __call = function(self, ...)
    local n = select('#', ...)
    local t = table.pack(...) assert(#t == n) if #t == 1 then t = t[1] end
    if type(t) ~= "table" then
      return t
    else
      local mt = getmetatable(t) if mt and mt[1]=="is_tuple" then return t end
      local new_tuple = tuple_constructor(t)
      local p = compute_hash(new_tuple) % NUM_BUCKETS
      local bucket = (list_of_tuples[p] or setmetatable({}, WEAK_MT))
      list_of_tuples[p] = bucket
      local max,n = 0,0
      for i,vi in pairs(bucket) do
	local equals = true
	for j,vj in ipairs(vi) do
	  if vj ~= new_tuple[j] then equals=false break end
	end
	if equals == true then return vi end
	max = math.max(max,i)
	n = n+1
      end
      if max/n > MAX_BUCKET_HOLES_RATIO then
	local new_bucket = {}
	for i,vi in pairs(bucket) do new_bucket[#new_bucket+1] = vi end
	list_of_tuples[p], bucket = new_bucket, new_bucket
	max = #bucket
	collectgarbage("collect")
      end
      bucket[max+1] = new_tuple
      return new_tuple
    end
  end,
}
setmetatable(tuple, tuple_mt)

----------------------------------------------------------------------------
------------------------------ UNIT TEST -----------------------------------
----------------------------------------------------------------------------

tuple.utest = function()
  local a = tuple(2,{4,5},3)
  local b = tuple(4,5)
  local c = tuple(2,a[2],3)
  assert(a == c)
  assert(b == a[2])
  assert(b == c[2])
end

-- returns the number of tuples "alive", the number of used buckets, and the
-- loading factor of the hash table
tuple.stats = function()
  local num_buckets = 0
  local size = 0
  for k1,v1 in pairs(list_of_tuples) do
    num_buckets = num_buckets + 1
    for k2,v2 in pairs(v1) do size=size+1 end
  end
  if num_buckets == 0 then num_buckets = 1 end
  return size,num_buckets,size/NUM_BUCKETS
end

return tuple
