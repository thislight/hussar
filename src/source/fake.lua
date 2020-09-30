local away = require "away"
local utils = require "hussar.utils"
local httputil = require "hussar.httputil"

local fake_connection = {}

function fake_connection:clone_to(new_t)
    return utils.table_deep_copy(self, new_t)
end

function fake_connection:create()
    return self:clone_to {
        flag_keep_alive = false,
        buffer_in = {},
        pos_in = 0,
        buffer_out = {},
        pos_out = 0,
        is_alive = true,
    }
end

---- Standard APIs ----
-- TODO: move to use of dataqueue
function fake_connection:read()
    local new_pos = self.pos_in + 1
    if #self.buffer_in >= new_pos then
        self.pos_in = new_pos
        return self.buffer_in[new_pos]
    else
        utils.hold_until(function()
            return #self.buffer_in > self.pos_in
        end)
        return fake_connection:read()
    end
end

function fake_connection:write(value)
    if self.is_alive then
        table.insert(self.buffer_out, value)
        return #value
    else
        error({
            t = 'closed',
            r = self.closed_reason,
        })
    end
end

function fake_connection:set_keep_alive(enable)
    local old = self.flag_keep_alive
    if enable ~= nil then
        self.flag_keep_alive = enable
    end
    return old
end

function fake_connection:is_keep_alive()
    return self.flag_keep_alive
end

function fake_connection:is_alive()
    return self.is_alive
end

function fake_connection:close(reason)
    self.is_alive = false
    self.closed_reason = reason
end
--------

function fake_connection:client_close()
    self.is_alive = false
end

function fake_connection:client_write(s)
    if self.is_alive then
        table.insert(self.buffer_in, s)
    else
        error({
            t = 'closed',
            r = self.closed_reason,
        })
    end
end

function fake_connection:client_read()
    local new_pos = self.pos_out + 1
    if #self.buffer_out > new_pos then
        self.pos_out = new_pos
        return self.buffer_in[new_pos]
    else
        utils.hold_until(
            function() return #self.buffer_in > new_pos end
        )
        return self:client_read()
    end
end

function fake_connection:client_is_keep_alive()
    return self:is_keep_alive()
end

local fake_source = {
    new_connections = {},
}

function fake_source:clone_to(new_t)
    local object = utils.table_deep_copy(self, new_t)
    object.new_connections = {}
    return object
end

function fake_source:pull()
    local copy = table.pack(table.unpack(self.new_connections))
    self.new_connections = {}
    return copy
end

function fake_source:new_connection()
    local conn = fake_connection:create()
    table.insert(self.new_connections, conn)
    return conn
end

function fake_source:add_request(t)
    local conn = self:new_connection()
    local request_s = httputil.request(t)
    conn:client_write(request_s)
    return conn
end

function fake_source:create()
    return self:clone_to {}
end

return fake_source
