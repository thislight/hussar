local away = require "away"
local utils = require "hussar.sutils"
local httpbuild = require "hussar.httpbuild"

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
    }
end

---- Standard APIs ----
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
    table.insert(self.buffer_out, value)
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
end
--------

local fake_source = {}

function fake_source:clone_to(new_t)
    return utils.table_deep_copy(self, new_t)
end

function fake_source:pull()
end

function fake_source:add_request(t)
end

function fake_source:create()
    return self:clone_to {
        requests_queue = {},
    }
end

return fake_source
