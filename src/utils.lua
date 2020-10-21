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

local away = require "away"

local function table_deep_copy(t1, t2)
    for k, v in pairs(t1) do
        if type(v) == 'table' then
            t2[k] = table_deep_copy(v, {})
        else
            t2[k] = v
        end
    end
    return t2
end

local function yield_wakeback()
    coroutine.yield {
        target_thread = away.get_current_thread(),
    }
end

local function hold_until(checkf)
    local wakeback_thread = away.get_current_thread()
    local new_thread = coroutine.create(function(checkf, wakeback_thread)
        while true do
            if checkf() then
                coroutine.yield {
                    target_thread = wakeback_thread,
                }
            else
                yield_wakeback()
            end
        end
    end)
    coroutine.resume(new_thread, checkf, wakeback_thread)
end

local function map(f, t)
    local iter
    if type(t) == 'table' then
        local ipairs_iter = ipairs(t)
        iter = function()
            local _, v = ipairs_iter()
            return v
        end
    else
        iter = t
    end
    return coroutine.wrap(function()
        local v = iter()
        if v then
            return f(v)
        else
            return nil
        end
    end)
end

local function gentable(iter)
    local t = {}
    for v in iter do
        table.insert(t, v)
    end
    return t
end

local function itself(v)
    return v
end

local function any(t)
    for v in map(itself, t) do
        if v then
            return true
        end
    end
    return false
end
return {
    table_deep_copy = table_deep_copy,
    yield_wakeback = yield_wakeback,
    hold_until = hold_until,
    map = map,
    gentable = gentable,
    itself = itself, 
    any = any,
}
