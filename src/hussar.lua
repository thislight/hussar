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

local function pcall_handler(handler, conn, priframe, pubframe)
    return pcall(handler, conn, priframe, pubframe)
end

local function hussar_managing_thread(hussar)
    local logger = hussar.logger:create("managing_thread")
    logger:info("hussar managing thread started")
    co.yield()
    while true do
        away.wakeback_later()
        local remove_later_index = {}
        local ipairs = ipairs
        local managed_connections = hussar.managed_connections
        for i, conn in ipairs(managed_connections) do
            local thread = conn.__binded_thread
            if not thread then
                remove_later_index[#remove_later_index+1] = i
            elseif co.status(thread) == 'dead' then
                remove_later_index[#remove_later_index+1] = i
            elseif conn:require_wakeback() then
                away.schedule_thread(thread)
            end
        end
        for _, i in ipairs(remove_later_index) do
            table.remove(managed_connections, i)
        end
    end
end

local hussar = {
    managed_connections = {},
    pubframe = {
        debug = false,
    },
    error_handler = function(conn, frame, pubframe)
        local msg = "Server Error"
        if pubframe.debug then
            msg = string.format("Handler Error: \n%s",frame.error)
        end
        httputil.respond_on(conn) {
            status = 500,
            msg
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

local function optional_call(f, ...)
    if f then
        return f(...)
    end
end

function hussar:run_handler(conn)
    away.schedule_task(function()
        local frame = {}
        local current_thread = away.get_current_thread()
        frame.current_thread = current_thread
        local pubframe = self.pubframe
        conn.__binded_thread = current_thread
        optional_call(conn.__before_handler_run, conn, frame, pubframe)
        local status, e = pcall_handler(self.handler, conn, frame, self.pubframe)
        if not status then
            frame.error = e
            local errhandler_stat, errhandler_e = pcall_handler(self.error_handler, conn, frame, self.pubframe)
            if not errhandler_stat then
                self.logger:error("error handler error", nil, errhandler_e)
            end
        end
        optional_call(conn.__after_handler_run, conn, frame, pubframe)
        conn.__binded_thread = nil
    end)
end

function hussar:add_connection()
    error("hussar:add_connection is deprecated and does not take any effect", 2)
end

function hussar:add_http_connection(connection)
    self:run_handler(connection)
    insert(self.managed_connections, connection)
end

local function start_managing_thread(...)
    local thread = coroutine.create(hussar_managing_thread)
    co.resume(thread, ...)
    away.schedule_thread(thread)
end

function hussar:start()
    assert(self.handler, "handler is not set")
    for i,s in ipairs(self.sources) do
        s:start(self)
    end
    start_managing_thread(self)
end

return hussar
