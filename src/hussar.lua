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
local httputil = require "hussar.httputil"
local table_deep_copy = require("hussar.utils").table_deep_copy
local powerlog = require "powerlog"
local co = coroutine
local insert = table.insert

local function patch_connection(conn, patch)
    return setmetatable(patch, { __index = conn })
end

local function hussar_managing_thread(hussar)
    local logger = hussar.logger:create("managing_thread")
    logger:info("hussar managing thread started")
    co.yield()
    while true do
        away.wakeback_later()
        local remove_later_index = {}
        local current_time = hussar.time_provider()
        local managed_descriptors = hussar.managed_descriptors
        for i, ds in ipairs(managed_descriptors) do
            local conn, promised_deadline, frame, binded_thread, raw_conn, conn_patch = table.unpack(ds)
            if not conn:is_keep_alive() and current_time > promised_deadline then
                conn:close('timeout')
                table.insert(remove_later_index, i)
            elseif coroutine.status(binded_thread) == 'dead' then
                if not conn:is_keep_alive() then conn:close("thread is dead") end
                table.insert(remove_later_index, i)
            elseif not conn:is_alive() then
                table.insert(remove_later_index, i)
            elseif binded_thread and conn:require_wakeback() then
                away.schedule_thread(binded_thread)
            end
        end
        for _, index in ipairs(remove_later_index) do
            table.remove(managed_descriptors, index)
        end
    end
end

local hussar = {
    managed_descriptors = {},
    time_provider = function()
        return os.time()
    end,
    pubframe = {},
    handler = function(conn, frame, pubframe)
        httputil.respond_on(conn) {
            status = 500,
            "Gateway could not handle your request: missing handler. Hussar Web Server/Lua"
        }
    end,
    sources = {},
    logger = powerlog:create("hussar"),
    connection_timeout = 30,
}

function hussar:clone_to(t)
    return table_deep_copy(self, t)
end

function hussar:attach_source(source)
    table.insert(self.sources, source)
    source:prepare(self)
end

function hussar:create()
    return self:clone_to {}
end

function hussar:add_connection(connection)
    local priframe = {}
    local patch = {}
    local patched_connection = patch_connection(connection, patch)
    local promised_deadline = self.time_provider() + self.connection_timeout
    local newthread = self.handler(patched_connection, priframe, self.pubframe)
    insert(self.managed_descriptors, {patched_connection, promised_deadline, priframe, newthread, connection, patch})
end

local function start_managing_thread(...)
    local thread = coroutine.create(hussar_managing_thread)
    co.resume(thread, ...)
    away.schedule_thread(thread)
end

function hussar:start()
    assert(self.handler, "handler is not set")
    start_managing_thread(self)
end

return hussar
