local away = require "away"
local utils = require "hussar.sutils"
local httpbuild = require "hussar.httpbuild"

local fake_connection = {}

function fake_connection:clone_to(new_t)
    return utils.table_deep_copy(self, new_t)
end

function fake_connection:create()
    return self:clone_to {
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
--------

local fake_source = {}

function fake_source:clone_to(new_t)
    return utils.table_deep_copy(self, new_t)
end

function fake_source:poll()
end

function fake_source:next()
end

function fake_source:add_request(t)
end

function fake_source:create()
    return self:clone_to {
        requests_queue = {},
    }
end

return fake_source
