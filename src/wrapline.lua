-- Copyright (C) 2020 thisLight
-- 
-- This file is part of hussar.
-- 
-- hussar is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- hussar is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with hussar.  If not, see <http://www.gnu.org/licenses/>.


local function call(wrapline, ...)
    local values = table.pack(...)
    for i, f in ipairs(wrapline) do
        values = table.pack(f(table.unpack(values)))
    end
    return table.unpack(values)
end

local OBJ_META = {
    __call = function(...)
        return call(...)
    end,
}

local function create(t)
    local new = t or {}
    setmetatable(new, OBJ_META)
    return new
end

local pack = table.pack
local move = table.move
local unpack = table.unpack

local function wrap_context(f, ...)
    local args = pack(...)
    return function(...)
        local new_args = pack(...)
        move(new_args, 1, #new_args, #args+1, new_args)
        move(args, 1, #args, 1, new_args)
        return f(unpack(new_args))
    end
end

local function getcopy(line)
    local v = table.pack(table.unpack(line))
    return create(v)
end

return {
    create = create,
    call = call,
    wrap_context = wrap_context,
    getcopy = getcopy,
}
