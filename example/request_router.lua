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
local Hussar = require "hussar"
local RequestHandler = require "hussar.request_router"
local FakeSource = require "hussar.source.fake"
local httputil = require "hussar.httputil"
local wrap_thread = require "hussar.wrap_thread"

local server = Hussar:create()
table.insert(server.logger.receivers, require("powerlog.stdout")())
server.logger.accept_level = 50
local source = FakeSource:create()
server:attach_source(source)

local Scheduler = away.scheduler

local Debugger = require "away.debugger"
-- local watchers = Debugger:set_default_watchers(Scheduler)
-- Debugger:unset_default_watchers(Scheduler, {before_run_step=watchers.before_run_step})

local router = RequestHandler:create {
    {'/$', function(request, frame, pubframe)
        return {
            status = 200,
            "Hello World"
        }
    end}
}

local function handler_auto_write(handler, conn)
    return function(...)
        local result = handler(...)
        if result then
            conn:write(httputil.response(result))
        elseif not conn:is_keep_alive() and conn:is_alive() then
            conn:close()
        end
    end
end

server.handler = wrap_thread(function(conn, frame, pubframe)
    local request = httputil.wait_for_request(conn)
    local user_handler = router:route(request, conn, frame, pubframe)
    frame.connection = conn
    handler_auto_write(user_handler, conn)(request, frame, pubframe)
end)

Scheduler:run_task(function()
    server:start()
end)

Scheduler:run_task(function()
    local conn = source:add_request {
        method = "GET",
        path = "/"
    }
    print(conn:read_and_wait())
    Scheduler:stop()
end)

Scheduler:run()
