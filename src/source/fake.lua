local away = require "away"
local utils = require "hussar.utils"
local httputil = require "hussar.httputil"
local Dataqueue = require "away.dataqueue"

local function create_fake_connection_buffer(hold_until)
    return {
        pointer = 0,
        alive = true,
        keep_alive = false,
        read = function(self)
            local new_pos = self.pointer + 1
            if #self >= new_pos then
                self.pointer = new_pos
                return self[new_pos]
            else
                hold_until(function()
                    return #self > self.pointer
                end)
                return self:read()
            end
        end,
        write = function(self, value)
            if self.alive then
                table.insert(self, value)
            else
                error({
                    t = 'closed',
                    r = self.closed_reason
                })
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
    }
end

local function create_connection_object(buffer, remote)
    return {
        buffer = buffer,
        remote = remote,
        read = function(self)
            if not self.buffer:is_alive() then
                error({
                    t = 'closed',
                    r = self.buffer.closed_reason
                })
            end
            return self.buffer:read()
        end,
        write = function(self, value)
            if not self.buffer:is_alive() then
                error {
                    t = 'closed',
                    r = self.buffer.closed_reason
                }
            end
            return self.remote:write(value)
        end,
        set_keep_alive = function(self, enable)
            if self.buffer:is_alive() then
                self.buffer:set_keep_alive(enable)
                self.remote:set_keep_alive(enable)
            else
                error({
                    t = 'closed',
                    r = self.buffer.closed_reason
                })
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
    }
end

local function create_fake_connection_pair()
    local server_side_buffer = create_fake_connection_buffer(utils.hold_until)
    local client_side_buffer = create_fake_connection_buffer(utils.hold_until)
    local server_side_conn = create_connection_object(server_side_buffer, client_side_buffer)
    local client_side_conn = create_connection_object(client_side_buffer, server_side_buffer)
    return server_side_conn, client_side_conn
end

local fake_source = {
    hussars = {},
}

function fake_source:clone_to(new_t)
    local object = utils.table_deep_copy(self, new_t)
    object.hussars = {}
    return object
end

function fake_source:new_connection()
    local server_side, client_side = create_fake_connection_pair()
    self:push_connection(server_side)
    return client_side, server_side
end

function fake_source:push_connection(conn)
    for _, v in ipairs(self.hussars) do
        v:add_connection(conn)
    end
end

function fake_source:add_request(t)
    local conn, server_conn = self:new_connection()
    local request_s = httputil.request(t)
    conn:write(request_s)
    return conn, server_conn
end

function fake_source:create()
    return self:clone_to {}
end

function fake_source:prepare(hussar)
    table.insert(self.hussars, hussar)
end

return fake_source
