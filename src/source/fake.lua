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
local utils = require "hussar.utils"
local httputil = require "hussar.httputil"
local Dataqueue = require "away.dataqueue"
local powerlog = require "powerlog"
local terr = require "hussar.terr"

local function create_fake_connection_buffer()
    return {
        pointer = 0,
        alive = true,
        keep_alive = false,
        wakeback_flag = false,
        read = function(self, yield)
            local new_pos = self.pointer + 1
            if #self >= new_pos then
                self.pointer = new_pos
                return self[new_pos]
            else
                self.wakeback_flag = true
                yield = yield or coroutine.yield
                yield()
                return self:read()
            end
        end,
        read_and_wait = function(self)
            return self:read(function()
                while true do
                    away.wakeback_later()
                    if #self > self.pointer then
                        break
                    end
                end
            end)
        end,
        has_new_data = function(self)
            return self[self.pointer+1] ~= nil
        end,
        write = function(self, value)
            if self.alive then
                table.insert(self, value)
                self.wakeback_flag = true
            else
                terr.errorT('fake_connection_buffer', 'closed', self.closed_reason)
            end
        end,
        is_alive = function(self)
            return self.alive
        end,
        close = function(self, reason)
            self.alive = false
            self.closed_reason = reason
        end,
        set_keep_alive = function(self, enable)
            self.keep_alive = enable
        end,
        is_keep_alive = function(self)
            return self.keep_alive
        end,
        require_wakeback = function(self)
            local flag = (#self > self.pointer) and self.wakeback_flag
            self.wakeback_flag = false
            return flag
        end,
    }
end

local function create_connection_object(buffer, remote)
    return {
        buffer = buffer,
        remote = remote,
        read = function(self, yield)
            if not self.buffer:is_alive() then
                terr.errorT('connection', 'closed', self.buffer.closed_reason)
            end
            return self.buffer:read(yield)
        end,
        write = function(self, value)
            if not self.buffer:is_alive() then
                terr.errorT('connection', 'closed', self.buffer.closed_reason)
            end
            return self.remote:write(value)
        end,
        set_keep_alive = function(self, enable)
            if self.buffer:is_alive() then
                self.buffer:set_keep_alive(enable)
                self.remote:set_keep_alive(enable)
            else
                terr.errorT('connection', 'closed', self.buffer.closed_reason)
            end
        end,
        close = function(self, reason)
            if self.buffer:is_alive() then
                self.buffer:close(reason)
                self.remote:close()
            end
        end,
        is_alive = function(self)
            return self.buffer:is_alive()
        end,
        is_keep_alive = function(self)
            return self.buffer:is_keep_alive()
        end,
        require_wakeback = function(self)
            return self.buffer:require_wakeback()
        end,
        read_and_wait = function(self)
            return self.buffer:read_and_wait()
        end,
        has_new_data = function(self)
            return self.buffer:has_new_data()
        end,
    }
end

local function create_fake_connection_pair()
    local server_side_buffer = create_fake_connection_buffer()
    local client_side_buffer = create_fake_connection_buffer()
    local server_side_conn = create_connection_object(server_side_buffer, client_side_buffer)
    local client_side_conn = create_connection_object(client_side_buffer, server_side_buffer)
    return server_side_conn, client_side_conn
end

local fake_source = {
    inactive_connections = {},
    time_provider = function()
        return os.time() * 1000
    end,
    timeout = 30,
    logger = powerlog:create("hussar.source.fake"),
}

function fake_source:clone_to(new_t)
    local object = utils.table_deep_copy(self, new_t)
    object.hussars = {}
    return object
end

function fake_source:new_connection()
    local server_side, client_side = create_fake_connection_pair()
    self:push_connection(server_side)
    self.logger:debugf("new connection added")
    return client_side, server_side
end

local function create_http_connection(fsource, conn)
    return httputil.connection.applied {
        raw = conn,
        __read = conn.read,
        __write = conn.write,
        __require_wakeback = conn.require_wakeback,
        __after_handler_run = function(httpconn, frame, pubframe)
            table.insert(fsource.inactive_connections, conn)
        end,
    }
end

function fake_source:push_connection(conn)
    if self.hussar then
        self:push_http_connection(create_http_connection(self, conn))
    end
end

function fake_source:push_http_connection(httpconn)
    self.hussar:add_http_connection(httpconn)
end

function fake_source:add_request(t)
    local conn, server_conn = self:new_connection()
    local request_s = httputil.request(t)
    conn:write(request_s)
    self.logger:debugf("add_request(): request is sent")
    return conn, server_conn
end

function fake_source:create()
    return self:clone_to {}
end

local function fake_source_connection_manager(self)
    local inactive_connections = self.inactive_connections
    local time_provider = self.time_provider
    local timeout = self.timeout
    coroutine.yield()
    while true do
        away.wakeback_later()
        local to_be_removed_indexs = {}
        local current_time = time_provider()
        local ipairs = ipairs
        for i, conn in ipairs(inactive_connections) do
            if conn:has_new_data() then
                away.schedule_task(function()
                    local httpconn = create_http_connection(self, conn)
                    local headers = httputil.wait_for_headers(httpconn)
                    httpconn.headers_ready = headers
                    self:push_http_connection(httpconn)
                end)
                to_be_removed_indexs[#to_be_removed_indexs+1] = i
            end
        end
        for _, i in ipairs(to_be_removed_indexs) do
            table.remove(inactive_connections, i)
        end
    end
end

function fake_source:prepare(hussar)
    self.hussar = hussar
    self.logger = hussar.logger:create("source.fake")
    self.logger:infof("attached")
end

function fake_source:start(hussar)
    if not self.manager_thread then
        local manager_thread = coroutine.create(fake_source_connection_manager)
        self.manager_thread = manager_thread
        coroutine.resume(manager_thread, self)
        away.schedule_thread(manager_thread)
    end
end

return fake_source
