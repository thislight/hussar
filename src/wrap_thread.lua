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


local create = coroutine.create
local resume = coroutine.resume
local status = coroutine.status
local terr = require "hussar.terr"
local pack = table.pack
local unpack = table.unpack
local remove = table.remove

return function(func)
    return function(...)
        local new_thread = create(func)
        local result = pack(resume(new_thread, ...))
        local stat = result[1]
        if not stat then
            terr.errorT('wrap_thread', 'firstcall_error', result[2], {
                thread = new_thread
            })
        elseif status(new_thread) == "dead" then
            result[1] = nil
            return unpack(result)
        else
            result[1] = new_thread
            return unpack(result)
        end
    end
end
