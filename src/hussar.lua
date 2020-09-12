local away = require "away"
local lphr = require "lphr"
local httputil = require "hussar.httputil"
local table_deep_copy = require("hussar.utils").table_deep_copy

local hussar = {}

function hussar:clone_to(new_t)
    return table_deep_copy(self, new_t)
end

function hussar:create()
    return self:clone_to {
        sources = {},
        td = {},
    }
end

function hussar:attach_source(source)
    source:listen(function(conn)
        hussar:accept_connection(conn)
    end)
    table.insert(self.sources, source)
end

local function reshape_headers(old, new)
    for _, t in ipairs(old) do
        local key = t[1]
        local value = t[2]
        if not new[key] then
            new[key] = {}
        end
        table.insert(new[key], value)
    end
    return new
end

local function conn_hander(conn, hussar_ins)
    local protocol_data = {}
    while conn:can_read() do
        lphr.parse_request(conn:read(), protocol_data)
    end
    if protocol_data.prev_pret > 0 then
        local body = lphr.get_body(protocol_data)
        local request = {
            method = protocol_data.method,
            path = protocol_data.path,
            headers = reshape_headers(protocol_data.headers, {}),
            body = body,
        }
        local response = {}
        local handle = nil -- TODO
        hussar_ins:handle_request(request, response, handle)
        if response.body then
            conn:write()
        end
    else
        conn:write(httputil.response {
            code = 400,
        })
    end
end

function hussar:accept_connection(conn)
    local new_thread = coroutine.create(conn_hander)
    coroutine.resume(new_thread, conn)
    away.schedule_thread(new_thread)
end

return hussar