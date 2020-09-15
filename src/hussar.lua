local away = require "away"
local httputil = require "hussar.httputil"
local table_deep_copy = require("hussar.utils").table_deep_copy

local hussar = {}

function hussar:clone_to(new_t)
    return table_deep_copy(self, new_t)
end

local function new_error_thread(f, hussar_t)
    local th = coroutine.create(f)
    coroutine.resume(th, hussar_t)
    return th
end

function hussar:create()
    return self:clone_to {
        sources = {},
        td = {},
        pubframe = {},
        error_thread = new_error_thread(function(self)
            while true do
                local signal = coroutine.yield()
                error(signal.err, 0)
                httputil.respond_on(signal.connection) {
                    status_code = 500,
                    "Server Internal Error"
                }
            end
        end),
    }
end

function hussar:attach_source(source)
    table.insert(self.sources, source)
end

local function conn_hander(conn, pubframe, handler, error_thread)
    local frame = {}
    coroutine.yield() -- break point, only run handler after scheduled
    local stat, err = pcall(handler, conn, frame, pubframe)
    if not stat then
        coroutine.yield {
            target_thread = error_thread,
            connection = conn,
            err = err,
            frame = frame,
            pubframe = pubframe,
            handler = handler,
        }
    else
        if not conn:set_keep_alive() then
            conn:close()
        end
    end
end

function hussar:accept_connection(conn)
    local new_thread = coroutine.create(conn_hander)
    table.insert(self.td, {conn, new_thread})
    coroutine.resume(new_thread, conn, self.pubframe, self.handler, self.error_thread)
    away.schedule_thread(new_thread)
end

return hussar